package main

import (
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"regexp"
	"strings"
	"time"
)

type target struct {
	name string
	base *url.URL
}

func mustURL(raw string) *url.URL {
	u, err := url.Parse(raw)
	if err != nil {
		panic(err)
	}
	return u
}

func newProxy(t target) *httputil.ReverseProxy {
	proxy := httputil.NewSingleHostReverseProxy(t.base)

	director := proxy.Director
	proxy.Director = func(r *http.Request) {
		director(r)

		// Audit/debug headers
		r.Header.Set("X-ScopeHub-Gateway", "xscopehub-obsgw")
		r.Header.Set("X-Forwarded-Host", r.Host)

		// Optional multi-tenant propagation placeholder:
		// tenant := r.Header.Get("X-ScopeHub-Tenant")
		// if tenant != "" {
		// r.Header.Set("X-Org-Id", tenant)
		// }
	}

	proxy.Transport = &http.Transport{
		Proxy:                 http.ProxyFromEnvironment,
		MaxIdleConns:          256,
		MaxIdleConnsPerHost:   128,
		IdleConnTimeout:       90 * time.Second,
		ResponseHeaderTimeout: 60 * time.Second,
	}

	proxy.ErrorHandler = func(w http.ResponseWriter, r *http.Request, err error) {
		http.Error(w, "gateway upstream error: "+err.Error(), http.StatusBadGateway)
	}

	return proxy
}

var traceIDRe = regexp.MustCompile(`^[0-9a-f]{32}$`)

func main() {
	vm := target{name: "victoriametrics", base: mustURL("http://victoriametrics:8428")}
	vl := target{name: "victorialogs", base: mustURL("http://victorialogs:9428")}
	oo := target{name: "openobserve", base: mustURL("http://openobserve:5080")}
	tp := target{name: "tempo", base: mustURL("http://tempo:3200")}

	vmProxy := newProxy(vm)
	vlProxy := newProxy(vl)
	ooProxy := newProxy(oo)
	tpProxy := newProxy(tp)

	mux := http.NewServeMux()

	// Metrics: /api/obs/v1/metrics/* -> VictoriaMetrics
	mux.HandleFunc("/api/obs/v1/metrics/", func(w http.ResponseWriter, r *http.Request) {
		r.URL.Path = strings.TrimPrefix(r.URL.Path, "/api/obs/v1/metrics")
		if r.URL.Path == "" {
			r.URL.Path = "/"
		}
		vmProxy.ServeHTTP(w, r)
	})

	// Logs: /api/obs/v1/logs/* -> VictoriaLogs
	mux.HandleFunc("/api/obs/v1/logs/", func(w http.ResponseWriter, r *http.Request) {
		r.URL.Path = strings.TrimPrefix(r.URL.Path, "/api/obs/v1/logs")
		if r.URL.Path == "" {
			r.URL.Path = "/"
		}
		vlProxy.ServeHTTP(w, r)
	})

	// Trace search (hot): /api/obs/v1/traces/search -> OpenObserve
	mux.HandleFunc("/api/obs/v1/traces/search", func(w http.ResponseWriter, r *http.Request) {
		r.URL.Path = "/api/traces/search"
		ooProxy.ServeHTTP(w, r)
	})

	// Traces routing: /api/obs/v1/traces/{trace_id} or /api/obs/v1/traces/go/{trace_id}
	mux.HandleFunc("/api/obs/v1/traces/", func(w http.ResponseWriter, r *http.Request) {
		if strings.HasPrefix(r.URL.Path, "/api/obs/v1/traces/go/") {
			id := strings.TrimPrefix(r.URL.Path, "/api/obs/v1/traces/go/")
			if traceIDRe.MatchString(id) {
				http.Redirect(w, r, "/api/obs/v1/traces/"+id, http.StatusFound)
				return
			}
			http.Error(w, "invalid trace_id", http.StatusBadRequest)
			return
		}

		id := strings.TrimPrefix(r.URL.Path, "/api/obs/v1/traces/")
		if id == "" || strings.Contains(id, "/") || !traceIDRe.MatchString(id) {
			http.Error(w, "invalid trace path; use /traces/search or /traces/{trace_id}", http.StatusBadRequest)
			return
		}

		r.URL.Path = "/api/traces/" + id
		tpProxy.ServeHTTP(w, r)
	})

	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})

	addr := ":8080"
	log.Println("XScopeHub Observability DataGateway listening on", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatal(err)
	}
}

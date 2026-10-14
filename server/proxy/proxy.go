package proxy

import (
	"io"
	"log"
	"net/http"
	"net/url"
	"strings"
	"time"
)

var proxyClient = &http.Client{
	Timeout: 45 * time.Second,
	CheckRedirect: func(req *http.Request, via []*http.Request) error {
		if len(via) >= 10 {
			return http.ErrUseLastResponse
		}
		return nil
	},
}

// ProxyHandler transparently forwards HTTP requests to target URL (e.g. YouTube API / Audio Streams)
// bypassing browser CORS restrictions and supporting HTTP 206 Range requests for audio streaming.
func ProxyHandler(w http.ResponseWriter, r *http.Request) {
	// Fallback if URL query parameter was not properly parsed
	rawTarget := r.URL.Query().Get("url")
	if rawTarget == "" && strings.HasPrefix(r.URL.RawQuery, "url=") {
		rawTarget, _ = url.QueryUnescape(strings.TrimPrefix(r.URL.RawQuery, "url="))
	}
	if rawTarget == "" {
		http.Error(w, "Missing 'url' query parameter", http.StatusBadRequest)
		return
	}

	targetURL := rawTarget

	parsedURL, err := url.Parse(targetURL)
	if err != nil || (parsedURL.Scheme != "http" && parsedURL.Scheme != "https") {
		http.Error(w, "Invalid target URL", http.StatusBadRequest)
		return
	}

	outReq, err := http.NewRequest(r.Method, targetURL, r.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Copy allowed incoming headers
	for key, values := range r.Header {
		lower := strings.ToLower(key)
		if lower == "host" || lower == "origin" || lower == "referer" || lower == "sec-fetch-mode" || lower == "sec-fetch-site" {
			continue
		}
		for _, v := range values {
			outReq.Header.Add(key, v)
		}
	}

	// Ensure appropriate User-Agent matching client parameter for Google CDN or realistic browser
	if strings.Contains(parsedURL.Host, "googlevideo.com") {
		cParam := parsedURL.Query().Get("c")
		if cParam == "IOS" {
			outReq.Header.Set("User-Agent", "com.google.ios.youtube/20.10.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)")
		} else if cParam == "ANDROID_MUSIC" {
			outReq.Header.Set("User-Agent", "com.google.android.apps.youtube.music/7.02.51 (Linux; U; Android 14) gzip")
		} else if cParam == "WEB" {
			outReq.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36")
		} else {
			outReq.Header.Set("User-Agent", "com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip")
		}
	} else if outReq.Header.Get("User-Agent") == "" {
		outReq.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36")
	}

	// Ensure consent cookie if calling YouTube to bypass EU consent redirect walls
	if strings.Contains(targetURL, "youtube.com") && outReq.Header.Get("Cookie") == "" {
		outReq.Header.Set("Cookie", "CONSENT=YES+cb; SOCS=CAISEwgDEgk2MTQ1MTY0ODcaAmVuIAEaBgiA_LuuBg")
	}

	resp, err := proxyClient.Do(outReq)
	if err != nil {
		log.Printf("[ProxyHandler] Error fetching %s: %v", targetURL, err)
		http.Error(w, "Upstream proxy error: "+err.Error(), http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	// Forward response headers, stripping Set-Cookie, Transfer-Encoding, CSP, HSTS, and WWW-Authenticate
	// to prevent upstream header buffer overflow and prevent triggering browser HTTP Basic Auth prompts.
	for key, values := range resp.Header {
		lower := strings.ToLower(key)
		if lower == "set-cookie" || lower == "transfer-encoding" ||
			lower == "content-security-policy" || lower == "strict-transport-security" ||
			lower == "connection" || lower == "www-authenticate" || lower == "proxy-authenticate" {
			continue
		}
		for _, v := range values {
			w.Header().Add(key, v)
		}
	}

	// Ensure CORS headers for browser
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, HEAD, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "*")
	w.Header().Set("Access-Control-Expose-Headers", "Content-Range, Content-Length, Accept-Ranges")

	statusCode := resp.StatusCode
	// CRITICAL: Upstream 401 Unauthorized MUST NOT be forwarded to the browser directly
	// as it causes the browser to prompt the user with a native HTTP Basic Auth "Sign in" popup.
	if statusCode == http.StatusUnauthorized {
		statusCode = http.StatusBadGateway
	}

	w.WriteHeader(statusCode)
	io.Copy(w, resp.Body)
}

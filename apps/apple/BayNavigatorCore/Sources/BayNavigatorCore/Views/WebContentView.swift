import SwiftUI
import WebKit

/// A native SwiftUI view that displays web content fetched from a URL
/// Used for Privacy Policy, Terms of Service, Credits, etc.
public struct WebContentView: View {
    let title: String
    let url: URL

    @State private var isLoading = true
    @State private var loadError: Error?

    public init(title: String, url: URL) {
        self.title = title
        self.url = url
    }

    public var body: some View {
        Group {
            if let error = loadError {
                errorView(error)
            } else {
                WebViewRepresentable(url: url, isLoading: $isLoading, loadError: $loadError)
                    .overlay {
                        if isLoading {
                            ProgressView("Loading...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(.regularMaterial)
                        }
                    }
            }
        }
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    @ViewBuilder
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Unable to Load Content")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Link(destination: url) {
                Label("Open in Browser", systemImage: "safari")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - WebView Representable

#if os(iOS) || os(visionOS)
private struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var loadError: Error?

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        // Inject CSS to adapt content to native app styling
        let script = """
        document.addEventListener('DOMContentLoaded', function() {
            // Remove navigation/header/footer if they exist
            var nav = document.querySelector('nav, header, footer, .navbar, .footer');
            if (nav) nav.style.display = 'none';

            // Add padding for better mobile display
            document.body.style.padding = '16px';
            document.body.style.paddingTop = '8px';
        });
        """
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(userScript)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, loadError: $loadError)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        @Binding var loadError: Error?

        init(isLoading: Binding<Bool>, loadError: Binding<Error?>) {
            _isLoading = isLoading
            _loadError = loadError
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
            loadError = nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            loadError = error
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            loadError = error
        }
    }
}
#elseif os(macOS)
private struct WebViewRepresentable: NSViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var loadError: Error?

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // Inject CSS to adapt content to native app styling
        let script = """
        document.addEventListener('DOMContentLoaded', function() {
            // Remove navigation/header/footer if they exist
            var nav = document.querySelector('nav, header, footer, .navbar, .footer');
            if (nav) nav.style.display = 'none';

            // Add padding for better display
            document.body.style.padding = '16px';
            document.body.style.paddingTop = '8px';
        });
        """
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(userScript)

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, loadError: $loadError)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        @Binding var loadError: Error?

        init(isLoading: Binding<Bool>, loadError: Binding<Error?>) {
            _isLoading = isLoading
            _loadError = loadError
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
            loadError = nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            loadError = error
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            isLoading = false
            loadError = error
        }
    }
}
#endif

#Preview {
    NavigationStack {
        WebContentView(
            title: "Privacy Policy",
            url: URL(string: "https://baynavigator.org/privacy")!
        )
    }
}

use std::sync::Arc;
use std::time::Duration;

use anyhow::Context;
use codex_backend_client::Client as BackendClient;
use codex_core::ProtectedDataModeExitFuture;
use codex_core::ProtectedDataModeExitPolicy;
use codex_login::AuthManager;
use codex_protocol::ThreadId;
use tracing::warn;

const POLICY_REQUEST_TIMEOUT: Duration = Duration::from_secs(5);

pub(crate) struct HostedProtectedDataModeExitPolicy {
    auth_manager: Arc<AuthManager>,
    backend_base_url: String,
}

impl HostedProtectedDataModeExitPolicy {
    pub(crate) fn new(backend_base_url: String, auth_manager: Arc<AuthManager>) -> Self {
        Self {
            auth_manager,
            backend_base_url,
        }
    }

    async fn fetch_can_exit(&self) -> anyhow::Result<bool> {
        let auth = self
            .auth_manager
            .auth()
            .await
            .context("ChatGPT auth not available")?;
        anyhow::ensure!(
            auth.uses_codex_backend(),
            "protected data mode exit requires Codex backend auth"
        );
        let account_id = auth
            .get_account_id()
            .context("ChatGPT account id not available")?;
        let mut client = BackendClient::from_auth(self.backend_base_url.clone(), &auth)
            .context("construct protected data mode policy client")?;
        client = client.with_chatgpt_account_id(account_id);
        if auth.is_fedramp_account() {
            client = client.with_fedramp_routing_header();
        }
        Ok(client.get_protected_data_mode_policy().await?.can_exit)
    }
}

impl ProtectedDataModeExitPolicy for HostedProtectedDataModeExitPolicy {
    fn can_exit(&self, thread_id: ThreadId) -> ProtectedDataModeExitFuture<'_> {
        Box::pin(async move {
            match tokio::time::timeout(POLICY_REQUEST_TIMEOUT, self.fetch_can_exit()).await {
                Ok(Ok(can_exit)) => Ok(can_exit),
                Ok(Err(err)) => {
                    warn!(
                        %thread_id,
                        %err,
                        "protected data mode exit policy unavailable; denying exit"
                    );
                    Ok(false)
                }
                Err(_) => {
                    warn!(
                        %thread_id,
                        "protected data mode exit policy request timed out; denying exit"
                    );
                    Ok(false)
                }
            }
        })
    }
}

#[cfg(test)]
mod tests {
    use codex_core::ProtectedDataModeExitPolicy;
    use codex_login::CodexAuth;
    use codex_protocol::ThreadId;
    use wiremock::Mock;
    use wiremock::MockServer;
    use wiremock::ResponseTemplate;
    use wiremock::matchers::header;
    use wiremock::matchers::method;
    use wiremock::matchers::path;

    use super::HostedProtectedDataModeExitPolicy;

    #[tokio::test]
    async fn backend_policy_allows_exit() {
        let server = MockServer::start().await;
        Mock::given(method("GET"))
            .and(path("/api/settings/protected_data_mode"))
            .and(header("authorization", "Bearer Access Token"))
            .and(header("chatgpt-account-id", "account_id"))
            .respond_with(ResponseTemplate::new(200).set_body_json(serde_json::json!({
                "available": true,
                "exit_enabled": true,
                "exit_allowed_by_workspace": true,
                "can_exit": true
            })))
            .mount(&server)
            .await;
        let policy = HostedProtectedDataModeExitPolicy::new(
            server.uri(),
            codex_login::AuthManager::from_auth_for_testing(
                CodexAuth::create_dummy_chatgpt_auth_for_testing(),
            ),
        );

        assert!(policy.can_exit(ThreadId::new()).await.unwrap());
    }

    #[tokio::test]
    async fn unavailable_policy_fails_closed() {
        let policy = HostedProtectedDataModeExitPolicy::new(
            "http://127.0.0.1:1".to_string(),
            codex_login::AuthManager::from_auth_for_testing(
                CodexAuth::create_dummy_chatgpt_auth_for_testing(),
            ),
        );

        assert!(!policy.can_exit(ThreadId::new()).await.unwrap());
    }
}

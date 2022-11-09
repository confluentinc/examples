/*
 * Copyright 2022 Confluent Inc.
 */

package io.confluent.examples.clients.cloud;

import static io.confluent.kafka.common.multitenant.oauth.OAuthBearerJwsToken.OAUTH_IDENTITY_POOL_PROPERTY_KEY;
import static io.confluent.kafka.common.multitenant.oauth.OAuthBearerJwsToken.OAUTH_NEGOTIATED_LOGICAL_CLUSTER_PROPERTY_KEY;

import java.io.IOException;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import javax.security.auth.callback.Callback;
import javax.security.auth.callback.UnsupportedCallbackException;
import javax.security.auth.login.AppConfigurationEntry;
import org.apache.kafka.common.config.ConfigException;
import org.apache.kafka.common.security.auth.AuthenticateCallbackHandler;
import org.apache.kafka.common.security.auth.SaslExtensions;
import org.apache.kafka.common.security.auth.SaslExtensionsCallback;
import org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule;
import org.apache.kafka.common.security.oauthbearer.OAuthBearerTokenCallback;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.Base64;

import org.jose4j.jwt.JwtClaims;
import org.jose4j.jwt.MalformedClaimException;
import org.jose4j.jwt.NumericDate;
import org.jose4j.jwt.consumer.InvalidJwtException;

import io.confluent.kafka.common.multitenant.oauth.OAuthBearerJwsToken;
/**
 * A {@code CallbackHandler} that recognizes {@link OAuthBearerTokenCallback} and retrieves OAuth 2
 * Bearer Token that was provided via the JAAS config. It also attaches the (logical) cluster this
 * token is allowed to work with as a SASL extension.
 *
 * <p>For example:
 *
 * <pre>
 * KafkaClient {
 *      org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule Required
 *      token="Token"
 *      logicalCluster="audi"
 *      identityPoolId="id"
 * };
 * </pre>
 *
 * <p>This class should be explicitly set via the {@code sasl.login.callback.handler.class} client
 * configuration property.
 */
public class OAuthBearerLoginWithIdentityPoolCallbackHandler
        implements AuthenticateCallbackHandler {
    private final Logger log =
            LoggerFactory.getLogger(OAuthBearerLoginWithIdentityPoolCallbackHandler.class);
    private String authToken;
    private String logicalCluster;
    private String identityPoolId;
    private boolean configured = false;

    @SuppressWarnings("unchecked")
    @Override
    public void configure(
            Map<String, ?> configs, String saslMechanism, List<AppConfigurationEntry> jaasConfigEntries) {
        if (!OAuthBearerLoginModule.OAUTHBEARER_MECHANISM.equals(saslMechanism)) {
            throw new IllegalArgumentException(
                    String.format("Unexpected SASL mechanism: %s", saslMechanism));
        }
        if (Objects.requireNonNull(jaasConfigEntries).size() != 1 || jaasConfigEntries.get(0) == null) {
            throw new IllegalArgumentException(
                    String.format(
                            "Must supply exactly 1 non-null JAAS mechanism configuration (size was %d)",
                            jaasConfigEntries.size()));
        }

        Map<String, String> moduleOptions =
                Collections.unmodifiableMap((Map<String, String>) jaasConfigEntries.get(0).getOptions());
        authToken = moduleOptions.get("token");
        log.info("Jing Liu token from jaas authToken " + authToken);
        if (authToken == null || authToken.isEmpty()) {
            log.error("No authentication token was provided in the JAAS config!");
            throw new ConfigException("Authentication token must be provided in the JAAS config.");
        }

        logicalCluster = moduleOptions.get("logicalCluster");
        log.info("Jing Liu logicalCluster from jaas config " + logicalCluster);
        if (logicalCluster == null || logicalCluster.isEmpty()) {
            log.error("No cluster extensions for the auth token was provided in the JAAS config!");
            throw new ConfigException("Cluster for token must be set in the JAAS config.");
        }

        identityPoolId = moduleOptions.get("identityPoolId");
        log.info("Jing Liu identityPoolId from jaas config " + identityPoolId);
        if (identityPoolId == null || identityPoolId.isEmpty()) {
            log.error("No identity Pool Id for the auth token was provided in the JAAS config!");
            throw new ConfigException("Identity Pool Id for token must be set in the JAAS config.");
        }
        configured = true;
    }

    @Override
    public void handle(Callback[] callbacks) throws IOException, UnsupportedCallbackException {
        if (!configured) {
            throw new IllegalStateException("Callback handler not configured");
        }

        log.info("Jing Liu handle ");
        for (Callback callback : callbacks) {
            if (callback instanceof OAuthBearerTokenCallback) {
                log.info("Jing Liu OAuthBearerTokenCallback");
                attachAuthToken((OAuthBearerTokenCallback) callback);
            } else if (callback instanceof SaslExtensionsCallback) {
                log.info("Jing Liu SaslExtensionsCallback");
                attachTenantLogicalCluster((SaslExtensionsCallback) callback);
            } else {
                log.info("Jing Liu UnsupportedCallbackException");
                throw new UnsupportedCallbackException(callback);
            }
        }
    }

    @Override
    public void close() {
        // empty
    }

    /*
       Attaches custom SASL extensions to the callback
    */
    private void attachTenantLogicalCluster(SaslExtensionsCallback callback) throws ConfigException {
        Map<String, String> extensions = new HashMap<>();
        extensions.put(OAUTH_NEGOTIATED_LOGICAL_CLUSTER_PROPERTY_KEY, logicalCluster);
        extensions.put(OAUTH_IDENTITY_POOL_PROPERTY_KEY, identityPoolId);
        callback.extensions(new SaslExtensions(extensions));
    }

    private void attachAuthToken(OAuthBearerTokenCallback callback) {
        if (callback.token() != null) {
            throw new IllegalArgumentException("Callback had a token already");
        }

        // token is passed in through JAAS (not built in Kafka),
        // therefore these constructor options are ignored
        String[] chunks = authToken.split("\\.");
        Base64.Decoder decoder = Base64.getDecoder();

        String payload = new String(decoder.decode(chunks[1]));
        NumericDate lifeTimeMs;
        NumericDate startTImeMs;
        String principal;
        try {
            JwtClaims claims = JwtClaims.parse(payload);
            lifeTimeMs = claims.getExpirationTime();
            principal = claims.getSubject();
            startTImeMs = claims.getIssuedAt();
        } catch (MalformedClaimException | InvalidJwtException e) {
            log.error("Failed to parse payload due to {}", e.getMessage());
            return;
        }
        callback.token(
                new OAuthBearerJwsToken(authToken, Collections.emptySet(), lifeTimeMs.getValueInMillis(), principal, startTImeMs.getValueInMillis()));
    }
}

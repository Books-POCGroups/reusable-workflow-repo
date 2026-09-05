/**
 * @name Hardcoded credentials
 * @description Detects hardcoded passwords, tokens, or API keys assigned
 *              to variables with security-sensitive names.
 * @kind problem
 * @problem.severity error
 * @security-severity 9.0
 * @precision high
 * @id java/hardcoded-credentials
 * @tags security
 *       external/cwe/cwe-798
 *       external/cwe/cwe-259
 */

import java

// Variables with security-sensitive names
predicate isCredentialVariable(Variable v) {
  v.getName().regexpMatch(
    "(?i).*(password|passwd|pwd|secret|apikey|api_key|token|auth|credential|private_?key|access_?key|client_?secret).*"
  )
}

// Filter out placeholder/test-like values
predicate looksLikeRealCredential(StringLiteral lit) {
  lit.getValue().length() >= 8 and
  not lit.getValue().regexpMatch(
    "(?i)(changeme|change\\.me|todo|fixme|placeholder|example|test|dummy|your.?|<[^>]*>|\\$\\{[^}]*\\}|#\\{[^}]*\\})"
  )
}

from Variable v, StringLiteral lit
where
  isCredentialVariable(v) and
  lit = v.getAnAssignedValue() and
  looksLikeRealCredential(lit)
select lit,
  "Possible hardcoded credential assigned to '" + v.getName() +
  "'. Use environment variables or a secrets manager instead."
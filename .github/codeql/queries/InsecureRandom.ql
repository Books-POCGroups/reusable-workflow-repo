/**
 * @name Insecure random number generator in security context
 * @description java.util.Random is not cryptographically secure.
 *              Use java.security.SecureRandom for tokens, nonces, and session IDs.
 * @kind problem
 * @problem.severity warning
 * @security-severity 7.4
 * @precision medium
 * @id java/insecure-random-security-context
 * @tags security
 *       external/cwe/cwe-338
 */

import java

predicate isSecurityContext(Variable v) {
  v.getName().toLowerCase().regexpMatch(
    ".*(token|nonce|salt|key|session|otp|csrf|captcha|challenge|random.?id|uuid).*"
  )
}

from ClassInstanceExpr newRandom, Variable target
where
  newRandom.getConstructedType().hasQualifiedName("java.util", "Random") and
  target.getAnAssignedValue() = newRandom and
  isSecurityContext(target)
select newRandom,
  "java.util.Random is not cryptographically secure. " +
  "Replace with java.security.SecureRandom for '" + target.getName() + "'."

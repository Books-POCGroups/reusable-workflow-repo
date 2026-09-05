/**
 * @name Sensitive data written to log
 * @description Logging credential or PII fields exposes them in log aggregators
 *              and may violate GDPR, PCI-DSS, or HIPAA requirements.
 * @kind problem
 * @problem.severity warning
 * @security-severity 6.5
 * @precision medium
 * @id java/sensitive-data-logging
 * @tags security
 *       external/cwe/cwe-532
 */

import java

// ── Logger call detection ─────────────────────────────────────
predicate isLoggerCall(MethodCall call) {
  call.getMethod().getName().regexpMatch("^(trace|debug|info|warn|error|fatal|log)$") and
  (
    call.getMethod().getDeclaringType().getASupertype*()
        .hasQualifiedName("org.slf4j", "Logger") or
    call.getMethod().getDeclaringType().getASupertype*()
        .hasQualifiedName("org.apache.logging.log4j", "Logger") or
    call.getMethod().getDeclaringType()
        .hasQualifiedName("java.util.logging", "Logger") or
    call.getMethod().getDeclaringType().getASupertype*()
        .hasQualifiedName("org.apache.log4j", "Logger")
  )
}

// ── Sensitive name check — takes a concrete string, no binding needed ─
bindingset[name]
predicate isSensitiveName(string name) {
  name.regexpMatch(
    "(?i).*(password|passwd|pwd|secret|token|apikey|api_key|"
    + "credit.?card|cvv|ssn|social.?security|dob|date.?of.?birth|pin).*"
  )
}

// ── Query ─────────────────────────────────────────────────────
from MethodCall log, Expr arg, string suspectName
where
  isLoggerCall(log) and
  arg = log.getAnArgument() and
  (
    // Local variable reference directly as argument
    exists(VarAccess va, LocalVariableDecl lv |
      va = arg and
      lv = va.getVariable() and
      suspectName = lv.getName() and
      isSensitiveName(suspectName)
    )
    or
    // Field access directly as argument (this.password, obj.secret)
    exists(FieldAccess fa |
      fa = arg and
      suspectName = fa.getField().getName() and
      isSensitiveName(suspectName)
    )
    or
    // Parameter passed directly as argument
    exists(VarAccess va, Parameter p |
      va = arg and
      p = va.getVariable() and
      suspectName = p.getName() and
      isSensitiveName(suspectName)
    )
    or
    // Local variable nested inside string concatenation / method call
    exists(VarAccess va, LocalVariableDecl lv |
      va.getParent+() = arg and
      lv = va.getVariable() and
      suspectName = lv.getName() and
      isSensitiveName(suspectName)
    )
    or
    // Field access nested inside string concatenation / method call
    exists(FieldAccess fa |
      fa.getParent+() = arg and
      suspectName = fa.getField().getName() and
      isSensitiveName(suspectName)
    )
  )
select log,
  "Possible logging of sensitive field `" + suspectName +
  "`. Avoid logging credentials and PII."

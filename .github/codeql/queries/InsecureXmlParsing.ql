/**
 * @name Insecure XML parser (XXE)
 * @description XML parsers configured without XXE mitigations are
 *              vulnerable to external entity injection attacks.
 * @kind problem
 * @problem.severity error
 * @security-severity 8.2
 * @precision medium
 * @id java/xxe-vulnerable-parser
 * @tags security
 *       external/cwe/cwe-611
 */

import java

class DocumentBuilderFactoryNewInstance extends MethodCall {
  DocumentBuilderFactoryNewInstance() {
    this.getMethod().getName() = "newInstance" and
    this.getMethod().getDeclaringType()
      .hasQualifiedName("javax.xml.parsers", "DocumentBuilderFactory")
  }
}

from DocumentBuilderFactoryNewInstance call, Variable v
where
  v.getAnAssignedValue() = call and
  // setFeature disabling external entities is NOT called on this factory
  not exists(MethodCall setFeature |
    setFeature.getMethod().getName() = "setFeature" and
    setFeature.getQualifier().(VarAccess).getVariable() = v and
    setFeature.getArgument(0).(StringLiteral).getValue()
        .matches("%external%entities%")
  )
select call,
  "DocumentBuilderFactory created without disabling external entity processing. " +
  "Call setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true) and disable " +
  "external-general-entities and external-parameter-entities features."

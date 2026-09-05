/**
 * @name JNDI injection (Log4Shell)
 * @description User-controlled data flowing into JNDI lookups enables
 *              remote code execution (Log4Shell, CVE-2021-44228).
 * @kind path-problem
 * @problem.severity error
 * @security-severity 10.0
 * @precision high
 * @id java/jndi-injection
 * @tags security
 *       external/cwe/cwe-917
 *       external/cwe/cwe-074
 */

import java
import semmle.code.java.dataflow.TaintTracking
import semmle.code.java.dataflow.FlowSources

class JndiLookupSink extends MethodCall {
  JndiLookupSink() {
    this.getMethod().getName() = "lookup" and
    this.getMethod().getDeclaringType()
        .getASupertype*().hasQualifiedName("javax.naming", "Context")
  }
}

module JndiConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) { src instanceof RemoteFlowSource }
  predicate isSink(DataFlow::Node sink) {
    exists(JndiLookupSink call | sink.asExpr() = call.getAnArgument())
  }
}

module JndiFlow = TaintTracking::Global<JndiConfig>;
import JndiFlow::PathGraph

from JndiFlow::PathNode source, JndiFlow::PathNode sink
where JndiFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "JNDI injection: user-controlled data from $@ reaches a JNDI lookup — " +
  "potential remote code execution (Log4Shell-class vulnerability).",
  source.getNode(), "this remote source"

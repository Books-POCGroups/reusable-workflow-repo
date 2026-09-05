/**
 * @name Open redirect
 * @description User-controlled data used in redirect responses without
 *              validation enables open redirect attacks.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision high
 * @id java/unvalidated-url-redirect
 * @tags security
 *       external/cwe/cwe-601
 */

import java
import semmle.code.java.dataflow.TaintTracking
import semmle.code.java.dataflow.FlowSources

class RedirectSink extends MethodCall {
  RedirectSink() {
    // HttpServletResponse.sendRedirect(url)
    this.getMethod().getName() = "sendRedirect" or
    // Spring HttpHeaders.setLocation(URI)
    (
      this.getMethod().getName() = "setLocation" and
      this.getMethod().getDeclaringType()
          .hasQualifiedName("org.springframework.http", "HttpHeaders")
    )
  }
}

module RedirectConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) { src instanceof RemoteFlowSource }
  predicate isSink(DataFlow::Node sink) {
    exists(RedirectSink rs | sink.asExpr() = rs.getAnArgument())
  }
}

module RedirectFlow = TaintTracking::Global<RedirectConfig>;
import RedirectFlow::PathGraph

from RedirectFlow::PathNode source, RedirectFlow::PathNode sink
where RedirectFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "Open redirect: user-controlled data from $@ flows into a redirect response.",
  source.getNode(), "this user input"

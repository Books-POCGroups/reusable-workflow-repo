/**
 * @name Stored XSS via rawkey and Param
 * @description Detects stored XSS where untrusted data read from a file or DB
 *              is written to HTTP response via PrintWriter without sanitization.
 * @kind path-problem
 * @id java/custom/stored-xss-rawkey
 * @tags security
 *       external/cwe/cwe-079
 * @problem.severity error
 * @precision high
 */

// ── Correct imports for CodeQL 2.x Java ──────────────────────
import java
import semmle.code.java.dataflow.TaintTracking
import semmle.code.java.dataflow.DataFlow

module StoredXssConfig implements DataFlow::ConfigSig {

  predicate isSource(DataFlow::Node source) {
    exists(MethodCall ma |
      ma.getMethod().getName()
          .regexpMatch("readFully|getRequestXMLString|getInputStream") and
      source.asExpr() = ma
    )
  }

  predicate isSink(DataFlow::Node sink) {
    exists(MethodCall ma |
      ma.getMethod().getName() = "write" and
      ma.getQualifier().getType().getName() = "PrintWriter" and
      sink.asExpr() = ma.getArgument(0)
    )
  }
}

// Instantiate the global taint-tracking flow
module StoredXssFlow = TaintTracking::Global<StoredXssConfig>;

// Required for path-problem queries
import StoredXssFlow::PathGraph

from StoredXssFlow::PathNode source, StoredXssFlow::PathNode sink
where StoredXssFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "Stored XSS: untrusted data from $@ reaches HTTP response without sanitization.",
  source.getNode(), "this source"

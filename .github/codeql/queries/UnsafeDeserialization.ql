/**
 * @name Unsafe deserialization
 * @description ObjectInputStream.readObject() on untrusted input can allow
 *              remote code execution via gadget chains.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 9.8
 * @precision high
 * @id java/unsafe-deserialization
 * @tags security
 *       external/cwe/cwe-502
 */

import java
import semmle.code.java.dataflow.TaintTracking
import semmle.code.java.dataflow.FlowSources

class ObjectInputStreamReadObject extends MethodCall {
  ObjectInputStreamReadObject() {
    this.getMethod().getName() = "readObject" and
    this.getMethod().getDeclaringType().hasQualifiedName("java.io", "ObjectInputStream")
  }
}

module DeserializationConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) {
    src instanceof RemoteFlowSource
  }

  predicate isSink(DataFlow::Node sink) {
    exists(ObjectInputStreamReadObject call |
      sink.asExpr() = call.getQualifier()
    )
  }
}

module DeserializationFlow = TaintTracking::Global<DeserializationConfig>;
import DeserializationFlow::PathGraph

from DeserializationFlow::PathNode source, DeserializationFlow::PathNode sink
where DeserializationFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "Unsafe deserialization: data from $@ reaches ObjectInputStream.readObject().",
  source.getNode(), "this remote source"
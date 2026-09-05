/**
 * @name Insecure deserialization (simple)
 * @description Detects calls to ObjectInputStream.readObject, which may be insecure if given untrusted data.
 * @kind problem
 * @problem.severity error
 * @security-severity 8.0
 * @precision medium
 * @id java/insecure-deserialization
 * @tags security
 *       external/cwe/cwe-502
 */

import java

class ObjectInputStreamReadObject extends MethodCall {
  ObjectInputStreamReadObject() {
    this.getMethod().hasName("readObject") and
    this.getMethod().getDeclaringType().hasQualifiedName("java.io", "ObjectInputStream")
  }
}

from ObjectInputStreamReadObject call
select call, "Potential insecure deserialization: call to ObjectInputStream.readObject()."
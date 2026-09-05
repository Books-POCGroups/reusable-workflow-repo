
/**
 * @name Weak cryptographic algorithm
 * @description Use of MD5, SHA-1, DES, RC4, or ECB mode is cryptographically weak.
 * @kind problem
 * @problem.severity warning
 * @security-severity 7.5
 * @precision very-high
 * @id java/weak-cryptographic-algorithm
 * @tags security
 *       external/cwe/cwe-327
 *       external/cwe/cwe-328
 */

import java

bindingset[alg]
predicate isWeakAlgorithm(string alg) {
  alg.toUpperCase().regexpMatch(
    "(MD5|MD4|MD2|SHA1|SHA-1|DES|3DES|DESEDE|RC2|RC4|ARCFOUR|BLOWFISH|.*/ECB/.*)"
  )
}

from MethodCall mc, StringLiteral algLit
where
  mc.getMethod().getName() = "getInstance" and
  (
    mc.getMethod().getDeclaringType()
        .hasQualifiedName("javax.crypto", ["Cipher", "Mac", "KeyGenerator"]) or
    mc.getMethod().getDeclaringType()
        .hasQualifiedName("java.security", ["MessageDigest", "Signature", "KeyPairGenerator"])
  ) and
  mc.getArgument(0) = algLit and
  isWeakAlgorithm(algLit.getValue())
select algLit,
  "Weak cryptographic algorithm '" + algLit.getValue() +
  "' detected. Use AES-256-GCM, SHA-256/512, or RSA-OAEP instead."

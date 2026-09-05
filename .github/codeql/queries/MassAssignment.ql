/**
 * @name Mass assignment vulnerability
 * @description Binding HTTP request parameters directly to a JPA entity
 *              or domain object may allow attackers to modify unintended fields.
 * @kind problem
 * @problem.severity warning
 * @security-severity 8.1
 * @precision medium
 * @id java/mass-assignment
 * @tags security
 *       external/cwe/cwe-915
 */

import java

// JPA-managed entity classes (javax and jakarta namespaces)
class JpaEntity extends Class {
  JpaEntity() {
    this.getAnAnnotation().getType()
        .hasQualifiedName("javax.persistence", "Entity") or
    this.getAnAnnotation().getType()
        .hasQualifiedName("jakarta.persistence", "Entity")
  }
}

// Spring MVC controller handler methods
class SpringHandlerMethod extends Method {
  SpringHandlerMethod() {
    this.getAnAnnotation().getType().getName()
        .regexpMatch(
          "(RequestMapping|GetMapping|PostMapping|PutMapping|PatchMapping|DeleteMapping)"
        )
  }
}

from SpringHandlerMethod handler, Parameter param
where
  handler.getAParameter() = param and
  param.getType().(RefType) instanceof JpaEntity and
  not exists(Annotation a |
    a = param.getAnAnnotation() and
    a.getType().getName() = "ModelAttribute"
  )
select param,
  "JPA entity '" + param.getType().getName() + "' bound directly in controller method '" +
  handler.getName() + "'. Use a DTO with explicit field mapping to prevent mass assignment."

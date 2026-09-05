/**
 * @name Spring Boot Actuator endpoint over-exposure
 * @description Enabling all Actuator endpoints (management.endpoints.web.exposure.include=*)
 *              without security exposes sensitive operational data and management APIs.
 * @kind problem
 * @problem.severity warning
 * @security-severity 7.5
 * @precision medium
 * @id java/spring-actuator-overexposure
 * @tags security
 *       external/cwe/cwe-200
 */

import java

// Detect @Value injection referencing actuator exposure properties
from Annotation valueAnnotation, StringLiteral val
where
  valueAnnotation.getType()
      .hasQualifiedName("org.springframework.beans.factory.annotation", "Value") and
  val = valueAnnotation.getValue("value").(StringLiteral) and
  val.getValue().regexpMatch(".*management\\.endpoints\\.web\\.exposure\\.include.*")
select valueAnnotation,
  "Actuator endpoint exposure is configured via @Value. Verify that wildcard exposure " +
  "(include=*) is restricted to authenticated or internal-only access."

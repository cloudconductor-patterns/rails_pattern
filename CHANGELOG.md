CHANGELOG
=========

## version 1.0.1 (2015/06/18)

  - Add dependency to build resources in the correct order.

## version 1.0.0 (2015/03/27)

  - Support CloudConductor v1.0.
  - Backup features have been omitted from this pattern. Use optional pattern (e.g. amanda_pattern) in conjuction with this pattern if you need backup features.

## version 0.3.2 (2014/12/24)

  - Support latest serverspec.
  - Add default CIDR to CloudConductorLocation parameter.
  - Add dependencies between SubnetRouteTableAssociation and EIP to specify remove order.
  - Remove unnecessary role file.
  - Add required packages to build nokogiri.
  - Brush up chef recipes on mysql_part and nginx_part.

## version 0.3.1 (2014/11/17)

  - Remove unused dependencies from backup_restore
  - Fix host parameter in case of creating user

## version 0.3.0 (2014/10/31)

  - First release of this pattern that contains rails and mysql

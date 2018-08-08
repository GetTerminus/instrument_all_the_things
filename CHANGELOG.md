# Pundit

## 1.0.0 (2018-08-08)

Remove deprecated methods. All prior methods (`increment`, `count` etc) have been replaced with `instrumentation_increment`, `instruementation_count` etc. This is to avoid issues with ActiveRecord and any other models which implement the commonly used `count` method.

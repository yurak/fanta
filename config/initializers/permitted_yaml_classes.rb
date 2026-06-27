# Rails 7.0 uses Psych 4 which restricts YAML class loading.
# During the upgrade process, use unsafe load to maintain backward compatibility
# with the audited gem which serializes BigDecimal and other types.
# TODO: Replace with explicit permitted_classes after full Rails 7.0 migration.
ActiveRecord.use_yaml_unsafe_load = true

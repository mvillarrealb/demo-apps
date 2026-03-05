# Schema Documentation: {{ metadata.database_info.database }}

Generated on: {{ metadata.generated_at | default('Unknown') }}

## Database Information

- **Vendor**: {{ metadata.database_info.vendor | default('Unknown') }}
- **Version**: {{ metadata.database_info.version | default('Unknown') }}
- **Database**: {{ metadata.database_info.database | default('Unknown') }}
- **User**: {{ metadata.database_info.user | default('Unknown') }}
- **Driver**: {{ metadata.database_info.driver_name | default('Unknown') }} v{{ metadata.database_info.driver_version | default('Unknown') }}
{% if metadata.database_info.schema %}
- **Schema**: {{ metadata.database_info.schema }}
{% endif %}

## Summary

- **Total Tables**: {{ metadata.table_metadata | length }}
- **Total Views**: {{ metadata.view_definitions | length }}
- **Total Functions**: {{ metadata.function_definitions | length }}
- **Total Triggers**: {{ metadata.trigger_definitions | length }}
- **Total Indexes**: {{ metadata.database_indexes | length }}
- **Total Foreign Keys**: {{ metadata.foreign_key_metadata | length }}

## Tables

{% for table_name, columns in metadata.table_metadata.items() %}
### {{ table_name }}

{% if metadata.table_row_count %}
**Estimated Row Count**: {{ metadata.table_row_count.get(table_name, 'Unknown') }}
{% endif %}

| Column | Type | Nullable | Default | Position |
|--------|------|----------|---------|----------|
{% for column in columns %}
| {{ column.column_name }} | {{ column.data_type }}{% if column.character_maximum_length %}({{ column.character_maximum_length }}){% elif column.numeric_precision %}({{ column.numeric_precision }}{% if column.numeric_scale %},{{ column.numeric_scale }}{% endif %}){% endif %} | {{ 'YES' if column.is_nullable else 'NO' }} | {{ column.column_default | default('NULL') }} | {{ column.ordinal_position }} |
{% endfor %}

{% if metadata.database_indexes %}
#### Indexes for {{ table_name }}

{% for index in metadata.database_indexes %}
{% if index.table_name == table_name %}
- **{{ index.index_name }}** ({{ index.index_type | default('Unknown') }})
  - Unique: {{ index.uniqueness | default('Unknown') }}
  - Columns: {{ index.columns | default('Unknown') }}
{% endif %}
{% endfor %}
{% endif %}

{% if metadata.foreign_key_metadata %}
#### Foreign Keys for {{ table_name }}

{% for fk in metadata.foreign_key_metadata %}
{% if fk.table_from == table_name %}
- **{{ fk.constraint_name }}**: {{ fk.column_from }} → {{ fk.schema_to }}.{{ fk.table_to }}.{{ fk.column_to }}
{% endif %}
{% endfor %}
{% endif %}

{% if metadata.trigger_definitions %}
#### Triggers for {{ table_name }}

{% for trigger in metadata.trigger_definitions %}
{% if trigger.table_name == table_name %}
- **{{ trigger.trigger_name }}**
  - Type: {{ trigger.trigger_type | default('Unknown') }}
  - Event: {{ trigger.triggering_event | default('Unknown') }}
  - Status: {{ trigger.status | default('Unknown') }}
{% endif %}
{% endfor %}
{% endif %}

---

{% endfor %}

## Views

{% if metadata.view_definitions %}
{% for view in metadata.view_definitions %}
### {{ view.view_name }}

**Updatable**: {{ view.is_updatable | default('Unknown') }}

```sql
{{ view.view_definition | default('Definition not available') }}
```

---

{% endfor %}
{% else %}
No views found in this schema.
{% endif %}

## Functions and Procedures

{% if metadata.function_definitions %}
{% for function in metadata.function_definitions %}
### {{ function.function_name }} ({{ function.function_type | default('Unknown') }})

```sql
{{ function.function_definition | default('Definition not available') }}
```

---

{% endfor %}
{% else %}
No functions or procedures found in this schema.
{% endif %}

## All Indexes

{% if metadata.database_indexes %}
| Table | Index Name | Type | Unique | Columns |
|-------|------------|------|--------|---------|
{% for index in metadata.database_indexes %}
| {{ index.table_name }} | {{ index.index_name }} | {{ index.index_type | default('Unknown') }} | {{ index.uniqueness | default('Unknown') }} | {{ index.columns | default('Unknown') }} |
{% endfor %}
{% else %}
No indexes found in this schema.
{% endif %}

## All Foreign Key Relationships

{% if metadata.foreign_key_metadata %}
| From Table | From Column | To Table | To Column | Constraint Name |
|------------|-------------|----------|-----------|-----------------|
{% for fk in metadata.foreign_key_metadata %}
| {{ fk.table_from }} | {{ fk.column_from }} | {{ fk.table_to }} | {{ fk.column_to }} | {{ fk.constraint_name }} |
{% endfor %}
{% else %}
No foreign key relationships found in this schema.
{% endif %}

---

*This documentation was automatically generated from the database schema.*
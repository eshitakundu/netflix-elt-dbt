{#- Bucket a year into its decade label, e.g. 1994 -> '1990s'. Null-safe. -#}
{% macro decade_of(year_column) -%}
    case
        when {{ year_column }} is null then null
        else cast(floor({{ year_column }} / 10) * 10 as integer)::varchar || 's'
    end
{%- endmacro %}

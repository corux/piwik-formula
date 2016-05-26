; <?php exit; ?> DO NOT REMOVE THIS LINE
; file automatically generated or modified by Piwik; you can manually override the default values in global.ini.php by redefining them in this file.
{%- macro ini_serialize(key, value) -%}
{%- if value is string or value is number %}
{{ key }} = {{ value|json }}
{%- elif value is iterable -%}
{%- for inner in value -%}
{{ ini_serialize(key, inner) }}
{%- endfor -%}
{%- endif -%}
{%- endmacro %}

{% for section, values in config.items() %}
[{{ section }}]
{%- for key, value in values.items() -%}
{{ ini_serialize(key, value) }}
{%- endfor %}
{% endfor %}

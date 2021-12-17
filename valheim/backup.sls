{% set current_datetime = None | strftime('%Y-%m-%d-%T')  %}

/Valheim_Backups:
  file.directory:
    - user: root
    - group: root
    - recurse:
      - user
      - group

{% for world in pillar['valheim']['lookup']['worlds'] %}
  {% for world_name, world_attrs in world.items()%}

/Valheim_Backups/{{world_name}}:
  file.directory
   
"Backup: Stop {{world_name}} service":
  service.dead:
    - name: valheim-{{world_name}}.service
    - retry:
        attempts: 5
        until: True
        interval: 20
        splay: 10

Create {{world_name}} Archive:
  cmd.run:
    - name: tar czpf /Valheim_Backups/{{ world_name }}/{{ current_datetime }}.tar.gz /Valheim_Worlds/{{world_name}}
    - require:
      - service: "Backup: Stop {{world_name}} service"

"Backup: Start {{ world_name }} service":
  service.running:
    - name: valheim-{{world_name}}.service

  {% endfor %}
{% endfor %}
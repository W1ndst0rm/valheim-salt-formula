include:
  - .backup

{% for world in pillar['valheim']['lookup']['worlds'] %}
  {% for world_name, world_attrs in world.items()%}

"Update: Stop {{world_name}} service":
  service.dead:
    - name: valheim-{{world_name}}.service
    - retry:
        attempts: 5
        until: True
        interval: 20
        splay: 10

Update Valheim via steamcmd for {{world_name}}: 
  cmd.run:
    - name: "/usr/games/steamcmd +@sSteamCmdForcePlatformType linux +login {{ pillar['steamcmd']['lookup']['username'] }} {{ pillar['steamcmd']['lookup']['password'] }}  +force_install_dir {{ pillar['valheim']['lookup']['install_dir'] }}/{{world_name}} +app_update 896660 validate +quit"
    - runas: steam

    {% for mod in world_attrs.mods %}
      {% for mod_name, mod_attrs in mod.items()%}

{{world_name}} Download {{mod_name}}:
  file.managed:
    - name: /tmp/{{mod_name}}/{{mod_name}}_{{mod_attrs.version}}.zip
    - source: https://{{mod_attrs.base_url}}/{{mod_attrs.version}}
    - makedirs: True
    - skip_verify: True
  
{{world_name}} Unzip {{mod_name}}:
  archive.extracted:
    - name: /tmp/{{mod_name}}/{{mod_name}}_{{mod_attrs.version}}/
    - source: /tmp/{{mod_name}}/{{mod_name}}_{{mod_attrs.version}}.zip
    - archive_format: zip
    - if_missing: /tmp/{{mod_name}}/{{mod_name}}_{{mod_attrs.version}}/
    - enforce_toplevel: False

{{world_name}} Install {{mod_name}}:
  cmd.run:
    - name: rsync --chown=steam:steam -r /tmp/{{mod_name}}/{{mod_name}}_{{mod_attrs.version}}/{{mod_attrs.source}} {{pillar['valheim']['lookup']['install_dir']}}/{{world_name}}/{{mod_attrs.install_dir}}

      {% endfor %}
    {% endfor %}

"Update: Start {{ world_name }} service":
  service.running:
    - name: valheim-{{world_name}}.service

  {% endfor %}
{% endfor %}
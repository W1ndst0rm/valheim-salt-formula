include:
 - steamcmd

/srv/valheim:
  file.directory:
    - user: steam
    - group: steam

/Valheim_Worlds:
  file.directory:
    - user: root
    - group: root

rsync:
  pkg.installed

{% for world in pillar['valheim']['lookup']['worlds'] %}
  {% for world_name, world_attrs in world.items()%}

/srv/valheim/{{world_name}}:
  file.directory:
    - user: steam
    - group: steam
    - recurse:
      - user
      - group

Install Valheim via steamcmd for {{world_name}}: 
  cmd.run:
    - name: "/usr/games/steamcmd +set_steam_guard_code HWR5M +@sSteamCmdForcePlatformType linux +login {{ pillar['steamcmd']['lookup']['username'] }} {{ pillar['steamcmd']['lookup']['password'] }}  +force_install_dir {{ pillar['valheim']['lookup']['install_dir'] }}/{{world_name}} +app_update 896660 validate +quit"
    - runas: steam
    - creates:
      - {{ pillar['valheim']['lookup']['install_dir'] }}/{{world_name}}/valheim_server_Data/app.info
      - {{ pillar['valheim']['lookup']['install_dir'] }}/{{world_name}}/steamapps/appmanifest_896660.acf
      - {{ pillar['valheim']['lookup']['install_dir'] }}/{{world_name}}/steam_appid.txt

/Valheim_Worlds/{{world_name}}:
  file.directory:
    - user: steam
    - group: steam

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

{{world_name}} fix steamclient.so:
  file.copy:
    - source: {{ pillar['valheim']['lookup']['install_dir'] }}/{{world_name}}/linux64/steamclient.so
    - name: {{ pillar['valheim']['lookup']['install_dir'] }}/{{world_name}}/steamclient.so
    - preserve: True
    - force: True

/etc/systemd/system/valheim-{{world_name}}.service:
  file.managed:
    - source: salt://valheim/templates/modded_service
    - template: jinja
    - default:
        port: 2456
    - context:
        install_dir: {{ pillar['valheim']['lookup']['install_dir'] }}/{{world_name}}
        world_name: {{world_name}}
        password: {{world_attrs.password}}
        port: {{world_attrs.port}}

valheim-{{world_name}}.service:
  service.running:
    - enable: True

  {% endfor %}
{% endfor %}
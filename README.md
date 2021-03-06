# log-sender-demo (Fluentd in docker container)

Input

* file
  * /data/log/nginx_access.log
  * /data/log/nginx_error.log

Output
* Elasticsearch


## Usage

### 1. Run Elasticsearch
```
$ docker run -d -p 9200:9200 --name es elasticsearch
```
See https://hub.docker.com/_/elasticsearch/


### 2. Create log schema (simple)
```bash
$ curl -X PUT localhost:9200/_template/access_app -d '
{
  "template" : "access_app-*",
  "mappings": {
    "_default_": {
      "dynamic_templates": [{"keyword": {
        "match_mapping_type": "string",
        "mapping": {"type": "string", "index": "not_analyzed"}
      }}],
      "_all": {"enabled": false}
    }
  }
}
'
```
return `{"acknowledged":true}`

### 3. Run Sample webserver
```
$ docker run -d -p 80:80 -v /tmp/log:/log bungoume/httpbin-container
```
See https://github.com/bungoume/httpbin-container


### 4. Start log-sender-demo
```
$ docker run -d --link es:elasticsearch.local -v /tmp/log:/data/log bungoume/log-sender-demo
```

### 5. Access webserver
create access log.
```bash
$ curl localhost/get
{
  "args": {},
  "headers": {
    "Accept": "*/*",
    "Content-Length": "",
    "Content-Type": "",
    "Host": "localhost",
    "User-Agent": "curl/7.29.0"
  },
  "origin": "172.17.42.1",
  "url": "http://localhost/get"
}
```


### 6. Start kibana and Visualize

```
$ docker run -d --link es:elasticsearch -p 5601:5601 kibana
```
Access http://localhost:5601/app/kibana

### 7. Configure Kibana
set "Index name or pattern": `access_app-*`, "Time-field name": `@timestamp`
and create.

### 8. Enjoy Kibana!


## Errors?
Check containers
```
$ docker ps
CONTAINER ID        IMAGE                        COMMAND                  CREATED             STATUS              PORTS                              NAMES
845e7e19c14b        kibana                       "/docker-entrypoint.s"   About an hour ago   Up About an hour    0.0.0.0:5601->5601/tcp             naughty_noyce
a145c0cc67a5        bungoume/log-sender-demo     "fluentd"                About an hour ago   Up About an hour                                       berserk_lumiere
5f39f37311cf        bungoume/httpbin-container   "supervisord -n"         About an hour ago   Up About an hour    0.0.0.0:80->80/tcp                 prickly_fermat
e0d8b23a4b22        elasticsearch                "/docker-entrypoint.s"   About an hour ago   Up About an hour    0.0.0.0:9200->9200/tcp, 9300/tcp   es
```
If not running someone, please check container log.

```
$ docker ps -a
CONTAINER ID        IMAGE                        COMMAND                  CREATED             STATUS                       PORTS                              NAMES
845e7e19c14b        kibana                       "/docker-entrypoint.s"   About an hour ago   Exited (137) 5 seconds ago                                      naughty_noyce
```
```
docker logs --tail=10 845e7e19c14b
```


## Memo

### Schema sample
```bash
PUT _template/access_app
{
  "template" : "access_app-*",
  "mappings": {
    "fluentd": {
      "dynamic_templates": [{"keyword": {
        "match_mapping_type": "string",
        "mapping": {"type": "string", "index": "not_analyzed"}
      }}],
      "_all": {"enabled": false},
      "properties":{
        "@timestamp": {"type":"date", "format": "epoch_millis"},
        "timestamp_ms": {"type":"date", "format": "epoch_millis"},

        "server_name": {"type":"string", "index": "not_analyzed"},
        "remote_addr": {"type":"ip"},
        "client_ip": {"type":"ip"},

        //http
        "host": {"type":"string", "index": "not_analyzed"},
        "method": {"type":"string", "index": "not_analyzed"},
        "path": {"type":"string", "index": "not_analyzed"},
        "query": {"type":"string", "index": "not_analyzed"},
        "status": {"type":"short"},

        "app_name": {"type":"string", "index": "not_analyzed"},
        "user": {"type":"string", "index": "not_analyzed"},
        "x_forwarded_for": {"type":"string", "index": "not_analyzed"},
        "x_forwarded_proto": {"type":"string", "index": "not_analyzed"},
        "accept_language": {"type": "string", "index": "not_analyzed"},
        "user_agent": {"type":"string", "index": "not_analyzed"},

        "res_bytes": {"type":"integer"},
        "req_body_bytes": {"type":"integer"},
        "res_body_bytes": {"type":"integer"},
        "referer": {"type":"string", "index": "not_analyzed"},
        "cookie": {"type":"string", "index":"no"},
        "taken_time_ms": {"type":"double"},
        "ua_os_family": {"type":"string", "index": "not_analyzed"},
        "ua_os_major_version": {"type":"integer"},
        "ua_os_version": {"type":"string", "index": "not_analyzed"},
        "ua_device": {"type":"string", "index": "not_analyzed"},
        "ua_browser_family": {"type":"string", "index": "not_analyzed"},
        "ua_browser_major_version": {"type":"integer"},
        "ua_browser_version": {"type":"string", "index": "not_analyzed"},
        "geo_city": {"type": "string", "index": "not_analyzed"},
        "geo_coordinates": {"type": "geo_point"},
        "geo_country_code": {"type": "string", "index": "not_analyzed"},
        "geo_region_code": {"type": "string", "index": "not_analyzed"},

        // uwsgi logs
        "app_worker": {"type": "string", "index": "not_analyzed"},

        // nginx logs
        "req_bytes": {"type":"integer"},
        "res_content_type": {"type": "string", "index": "not_analyzed"},
        "res_content_encoding": {"type": "string", "index": "not_analyzed"},
        "scheme": {"type": "string", "index": "not_analyzed"},
        "upstream_taken_time_ms": {"type":"double"},
        "upstream_addr": {"type": "string", "index": "not_analyzed"},
        "upstream_cache_status": {"type": "string", "index": "not_analyzed"},
        "res_cache_control": {"type": "string", "index": "not_analyzed"},
        "req_cache_control": {"type": "string", "index": "not_analyzed"},
        "connection": {"type":"integer"},
        "connection_requests": {"type":"integer"}
      }
    }
  }
}
```


## Build (for developer or offline user)

```
$ sudo docker build -t bungoume/log-sender-demo .
```

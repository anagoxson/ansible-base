# Ansible best practice

* ansibleベストプラクティス構造を雑に生成。
* インベントリは基本yaml。
* vagrantfileを一応生成してインベントリに対応。
* roleは適宜ansible-galaxyなどで追加。

## command

```
$ ./make_best_plactices.sh example
```

## structure

```
example/
├── Vagrantfile
├── ansible.cfg
├── common.yml
├── db.yml
├── inventories
│   ├── development
│   │   ├── group_vars
│   │   │   ├── all.yml
│   │   │   ├── db.yml
│   │   │   └── web.yml
│   │   ├── host_vars
│   │   │   ├── all.yml
│   │   │   ├── db01.yml
│   │   │   └── web01.yml
│   │   └── hosts.yml
│   ├── production
│   │   └── (same as develop)
│   └── staging
│       └── (same as develop)
├── roles
│   └── server_info
│       └── tasks
│           └── main.yml
├── site.yml
└── web.yml
```
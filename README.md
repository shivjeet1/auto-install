## Auto-Install
**Auto-Install** is a project which aims to create a custom ISO image for easy **unattended installation** of the mighty [Archlinux](https://archlinux.org)

This project creates ISO image which is suitable for installation in cloud environment and environments requiring unattended installation. The ISO does not use cloud-init, netboot and etc.

---

### Usage
- **Fork** or **Clone** this repo:
    - For cloning:
        ```bash
        git clone https://github.com/0xguava/auto-install.git
        cd auto-install
        ```
    - Or else fork it and clone the fork.

- **Setting up configuration:** Put the hostname and user credentials in the `config.json` file.

    Eg.
    ```json
    {
        "hostname": "arch",
        "adduser": "y",
        "credentials": {
            "username": "lol",
            "password": "lol",
            "rootpassword": "lol"
        }
    }
    ```
    > **NOTE**: adduser can be only set to `y/n` indicating whether to add a normal user or not.
    > - If want to add normal user then set `"adduser": "y"` and set `username` and `password` of your choice.
    > - If do not want to add user then either set `"adduser": "no"` or leave all concerned fields empty.

- **IMP**: Do not forget to add `rootpassword` in `config.json`

- **Add**, **commit** and **push** `config.json` to your repository:
    ```bash
    git add config.json
    git commit -m 'commit message.'
    git push origin master
    ```
    > **NOTE**: If directly cloning this repo, then you have to set the `origin` to you own repo.
    > - Create your a new repo on your github account.
    > - Set the `origin`: 
    >```bash
    >git remote set-url origin <url to your repo> 
    >```

- Create and push **tag**:
    ```bash
    git tag autoins.lolconfig
    git push origin autoins.lolconfig

    ```
    > `lolconfig` can be different in your case. Keep it as you like but do not change the `autoins.` part.

Once workflow is done then you can have your **custom unattended installation iso** with configurations from `config.json` in releases.

---

### Contributer
- [0xguava](https://0xgauva.github.io/)
- [shivjeet1](https://shivjeet1.github.io)

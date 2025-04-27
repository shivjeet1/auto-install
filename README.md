## Auto-Install

**Auto-Install** is a project which aims to create a custom ISO image for easy **unattended installation** of the mighty [Archlinux](https://archlinux.org).

This project creates ISO image which is suitable for installation in cloud environment and environments requiring unattended installation. The ISO does not use cloud-init, netboot and etc.
ISO creation takes place via Github Workflow.

The system installed by the **custom ISO image** obtained from this repository's releases will be minimal with enough packages required to run the system.

Anyone can have their own custom ISO image for unattended installation of Archlinux just by following further instructions.

---

**Announcement**: ***Further work to provide the complete customized ISO of Archlinux will be carried out.*** 

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
            "username": "user",
            "password": "vihs",
            "rootpassword": "vihs"
        }
    }
    ```
    > **NOTE**: adduser can be only set to `y/n` indicating whether to add a normal user or not.
    > - If want to add normal user then set `"adduser": "y"` and set `username` and `password` of your choice.
    > - If do not want to add user then either set `"adduser": "n"` or leave all concerned fields empty.

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
    >    ```bash
    >    git remote set-url origin <url to your repo> 
    >    ```

- Create and push **tag**:
    ```bash
    git tag autoins.lolconfig
    git push origin autoins.lolconfig
    ```
    > `lolconfig` can be different in your case. Keep it as you like but do not change the `autoins.` part.

Once workflow is done then you can have your **custom unattended installation ISO image** with configurations from `config.json` in repo's releases.

---

### Working/File info

This repository contains in total five files.

- `arch.sh`: This is the most important file as the whole installation within the live ISO environment is carried out by this file.
This the installation script which is already present in the live ISO env.

- **Workflow file**: This file runs the github workflow, which is responsible for creating custom ISO and uploading it to **Repo's Releases**.
Basically this file manages the workflow of Github's CI/CD for this project.

- `buildiso.sh`: This file contains all the instructions for customizing the live ISO env and is responsible for creating a custom ISO image.
This file puts `arch.sh` and `config.sh` to custom ISO so these files are available in live ISO env. It's executed by `worflow file`.

- `config.json`: It's the configuration file, which contains user configuration and other basic info. 

- `README.md`: This file contains what you are reading right now.

Workflow is triggered when a `tag` is pushed and then the whole thing is done and managed in workflow.

---

### Contributers

- [0xguava](https://0xgauva.github.io/)
- [shivjeet1](https://shivjeet1.github.io)

---

### Demonstration Video
https://github.com/shivjeet1/auto-install/raw/refs/heads/master/demo.mkv

---

### To All

:v: One Love

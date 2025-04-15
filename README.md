## Auto-Install
Project **Auto-Install** aim to create an ISO image for easy **unattended installation** of [archlinux](https://archlinux.org)

This project creates ISO image which is suitable for installation in cloud environment and environments requiring unattended installation.

---

### Usage
- Fork this repo or clone it.
    - If cloning
    ```bash
    git clone https://github.com/0xguava/auto-install.git
    cd auto-install
    ```
    - Or else fork it.

- Put the user credentials and hostname in the `config.json` file.
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
#### NOTE: adduser can be only set to `y/n` indicating whether to add a normal user or not. If not willing to add user then leave `username` and `password` blank.

- Do not forget to add root password

- Simply add, commit and push to the repository.

---

### Contributer
- [0xguava](https://0xgauva.github.io/)
- [shivjeet1](https://shivjeet1.github.io)



### unbound-manager

#### Note: I'm looking for assistance in identifying more lists that prohibit ADs.
---
### Installation
Lets first use `curl` and save the file in `/usr/local/bin/`
```
curl https://raw.githubusercontent.com/complexorganizations/unbound-manager/main/unbound-manager.sh --create-dirs -o /usr/local/bin/unbound-manager.sh
```
```
chmod +x /usr/local/bin/unbound-manager.sh
```
It's finally time to execute the script
```
bash /usr/local/bin/unbound-manager.sh
```
---
### Features
- Install, manage your own DNS
- DNSSEC Validation
- DNS Proxy
- Blocking based on DNS

---
### Variants
| Variants               |
| ---------------------  |
| [Host](https://raw.githubusercontent.com/complexorganizations/unbound-manager/main/configs/host) |

---
### Creating and updating a list
Let's begin by cloning the repository.
```
git clone --depth 1 https://github.com/complexorganizations/unbound-manager
```
Open `main.go` if you wish to alter the domain sources. After that update the urls array.
```
go run main.go
```

---
### Q&A
What's the best way for me to make my own list?
- Open the repo after forking and cloning it. Go ahead and change the `urls` struct, replacing the urls there with the lists you wish to use, and then just run the file using the command `go run main.go`.

What's the best way to add my own exclusions?
- Simply open the exclusion file, add a domain, and submit a pull request; if your pull request is merged, the domain will be excluded the next time the list is updated.

Is the list updated on a regular basis?
- We strive to update the list every 24 hours, but this cannot be guaranteed, and if it is not updated for any reason please let us know.

Why are you only banning it on the DNS level rather than the system level?
- It's a good idea to prohibit something on a system level rather than a DNS level, however some devices can't prohibit it on a system level (for example, smart devices), therefore a dns level is preferred.

Is it possible for me to utilize your list without utilizing Unbound Manager?
- `https://raw.githubusercontent.com/complexorganizations/unbound-manager/main/configs/host`

How can I get credit if I own one of the lists you're using?
- Please make a pull request.

---
### Author
* Name: Prajwal Koirala
* Website: [prajwalkoirala.com](https://www.prajwalkoirala.com)

---
### Credits
Open Source Community

| Author                 | URL                    | License                |
| ---------------------  | ---------------------  | ---------------------  |
| Steven-Black-Ads       | https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts | MIT |
| Light-Switch-Ads       | https://raw.githubusercontent.com/lightswitch05/hosts/master/docs/lists/ads-and-tracking-extended.txt | Apache License 2.0 |
| Notracking-Trackers    | https://raw.githubusercontent.com/notracking/hosts-blocklists/master/unbound/unbound.blacklist.conf | UNKNOWN |
|                        |                        |                        |

---
### License
Copyright © [Prajwal](https://github.com/prajwal-koirala)

This project is unlicensed.

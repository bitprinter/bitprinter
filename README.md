bitprinter
==========


Proposal
--------

The goal of this project is to establish workable designs and software for a secure, user-friendly, special-purpose computer or appliance that will improve a person's abilitiy to deal with cryptography safely. This device will be extensible, easy to use, and will work completely offline (air-gapped). Above all else, each user should always have the opportunity to adapt this project to suit whatever similar needs that might arise.


Hardware
--------

There are no specific hardware requirements but the device will need to consist of the following:

1. A Computer

The computer will need to be capable of working with strong cryptographic libraries, managing the user interface, and directing output to a printer.


2. A User Interface

The user interface will be handled collectively by some display and input device(s). These should be kept as simple as possible to reduce the amount of software needed on the computer (display drivers, X, gtk and so on) as well as to reduce the likelihood of keylogging attacks. If the user will need to input a password or passphrase then using a keyboard could be deemed necessary. In this case the keyboard should be wired rather than wireless, simple rather than feature-heavy, used only for this specific device, and stored securely when not in use. A camera may also be included in order to scan QR codes as binary input, to collect entropy, or whatever else but this is not currently being considered here.


3. A Printer

All persistent output will be produced by the printer since this removes the need to connect to any networks or transportable storage devices. The printer should be as simple as possible. Most importantly, the printer should not have any storage capabilities whatsoever. It should be capable of printing human-readable text and QR codes (or some other binary blob). It may be worth mentioning that this assumes that the average person will find it easier to secure peices of paper than computers connected to the internet.


* * *


An attempted design will consist of:

1. Raspberry Pi (including power supply and SD card)
2. 16x2 LCD + 5 button keypad (up/down/left/right/select)
3. Thermal POS printer


You might also try:

1. Some old desktop
2. The keyboard and monitor that came with it
3. The old printer in the same pile as the desktop


Software
--------

The specific feature-set should be entirely customizable by the end user. Once set up, it should be easier for an average user to perform these functions safely on this air-gapped appliance than a personal computer running current consumer software. Select a mode, configure, print the required data. This project hopes to cover the following:

1. Bitcoin addresses -- Standard, BIP0038, Brain Wallet, Vanity Wallet
2. PGP Keys
3. SSL Keys & Certificates
4. TOR Hidden Service Keys
5. Passphrases (eg. Diceware)
6. PRNG/RNG source (from user seed or hardware)


Auditing
--------

Write little code
prefer scripts
publish methods
print out all inputs by default in a way that can lead to the same outputs

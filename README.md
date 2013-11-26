bitprinter
==========


Proposal
--------

The goal of this project is to establish workable designs and software for a secure, user-friendly, special-purpose computer or appliance that will improve a person's ability to deal with cryptography safely. This device will be extensible, easy to use, and will work completely offline (air-gapped). Above all else, each user should always have the opportunity to adapt this project to suit whatever similar needs might arise.


Hardware
--------

There are no specific hardware requirements, but the bitprinter will need the following components:

1. A Computer -- This will need to be capable of working with strong cryptographic libraries, managing the user interface, and directing output to a printer.

2. A User Interface -- This will be handled collectively by some combination of displays and input devices. These should be kept as simple as possible to reduce the amount of software needed on the computer (display drivers, X, gtk and so on) as well as to reduce the likelihood of keylogging or other side channel attacks. If the user will need to input a password or passphrase then using a keyboard might be necessary for ease of use. In this case the keyboard should be wired rather than wireless, simple rather than feature-heavy, used only for this specific device, and stored securely when not in use. A camera may also be included in order to scan QR codes as binary input or to collect entropy (etc.) but this is not currently being considered here.

3. A Printer -- All persistent output will be produced by the printer since this removes the need to connect to any networks or transportable storage devices. This assumes that the average person will find it easier to secure pieces of paper than computers connected to the internet. The printer should be as simple as possible. Most importantly, the printer should not have any storage capabilities whatsoever. It should be capable of printing human-readable text and QR codes (or some other portable binary blob).

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

The specific feature-set should be entirely customizable by the end user. Once set up, it should be easier for an average user to perform these functions safely on this air-gapped appliance than on a personal computer running current consumer software. Just select a mode, configure, and print the required data.

This project hopes to cover the following:

1. Bitcoin addresses -- Standard, BIP0038, Brain Wallet, Vanity Wallet
2. PGP Keys
3. SSL Keys & Certificates
4. TOR Hidden Service Keys
5. Passphrases (eg. Diceware)
6. (Pseudo-) Random Number Generator (from user seed or hardware)


Entropy
-------

Entropy is a particularly difficult thing to have confidence in. If desired, a user should always be able to directly seed a given function with their own source of entropy. This may be a series of dice rolls, a passphrase, button mashing, or ideally anything the user has decided to trust. This will undoubtedly introduce usability issues as few people will want to roll a die 100 times and then enter the results into a computer by hand. The Raspberry Pi's BCM2835 SoC includes a hardware random number generator. It is up to the user to decide if this is trustworthy enough to use on a case-by-case basis, but it should be an option if present.


Persistence
-----------

Except in the case of special usability needs, bitprinter should never store anything to disk. All data that needs to persist after shutdown should be saved by printing. Bitprinter should boot up and shutdown extremely quickly and without any user intervention in order to encourage leaving it turned off while it is not in use. The entire contents of memory should be wiped during each shutdown to protect against cold-boot attacks.


Auditing
--------

Ensuring the auditability of the bitprinter will help discourage any attacks that could leave traces behind. Therefore this project will aim to produce as little code as possible, preferring to combine and configure already mature software. Absolutely no cryptographic primitives, standards, or algorithms will be developed for this project. Scripts will be preferred over binary executables. Documentation and tests will cover as much of the codebase as possible.

It is important to understand that there is no such thing as a perfectly secure system. In the event of an attack, it may prove valuable to be able to look back on the inputs used to arrive at the compromised results. Similarly, the inputs used during the generation of keys or addresses will be needed if and when anyone wants to verify the results independently on a separate machine. Whenever possible, an audit log will be printed in the form of itemized QR codes. These logs should be complete enough to entirely reproduce the output of the bitprinter. The audit logs should be treated as at least as sensitive as private keys and should be stored or destroyed accordingly. 

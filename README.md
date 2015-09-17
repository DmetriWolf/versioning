# Versioning
D module for using boolean operations with version and debug statements. Use OR, XOR, AND, and NOT as well as creating Umbrealla versions (which act as a master switch to turn on all asociated versions) and Base versions (which are turned on if any of their associated versions are turned on).
```D
import versioning;
mixin(Version("apple","XOR","banana")); //<--mixins must be at module scope
void main(){
	version(appleXORbanana) writeln("Version of only a single fruit.");
	version(bananaXORapple) writeln("Exactly the same as above.");
}
```
##How to use:
####Step 1 
Download the file and add the source to your compiler's import paths.
If you're using dub, it can do this for you if you add versioning to your dependencies in your dub.json file.
```JSON
{
	"name": "myproject",
	"dependencies": {
	  "versioning":    ">=1.0.0"
	}
}
```
####Step 2
Import the module into your project.
```D
module mymodule;
import versioning;
```
####Step 3
When you require a debug or version statement that needs a boolean operation done on it add the operation to your code in the version or debug statement (depending on your requirements):
```D
debug(x32ANDWindows) writeln("You're debugging for a 32bit Windows machine!");
version(WindowsORLinux) writeln("You're either using Windows or Linux.");
version(NOTMac) writeln("You're not using a Mac.");
```
####Step 4
Then, at `MODULE SCOPE` add a mixin for those same versions. You can do this the readable way or the functional way, there's no difference to the produced code. Binary operators will produce both a forward and backward version of the same resulting version eg aANDb bANDa, this is to protect you from Murphy's law. You will however, have to be careful about your order of operations which will be discussed further down.
```D
module mymodule;
import versioning;

mixin(Version("Windows","OR","Linux"));
mixin(Debug("x32", "AND", "Windows"));
mixin(Version("NOT","Mac"));
//or
mixin(VersionOR("Windows","Linux"));
mixin(DebugAND("x32","Windows"));
mixin(VersionNOT("Mac"));
```
####Step 5

When debugging, just compile your program with the version you want to look at and Versioning will take care of switching on the right versions.

***
##Functions
###Order of Operations
You are advised to be careful about what order you define the mixins for your versions if you're doing anything even slightly complicated. You must evealuate if a version is on or not (provide the mixin) before you use it (in a mixin or elsewhere). Here is the advised order to declare your mixins, deviate at your own risk:
* Umbreallas: declare these first as they'll switch on groups of versions for the other mixins to use.
* NOT: you can use NOT any time after you've declared umbrellas if you're not feeding.
* AND, OR, XOR, ManyAND: put them in an order that accomplishes what you want, after umbrellas, be careful when feeding.
* Base: Use these last as they're switched on by a list of other versions.

###Feeding is Undefined
While it's useful to feed results into mixins, you're advised to be caucious. Something like mixin(version("NOTvvv","OR","mmm")); is legal, but in order for it to work you must have a mixin(version("NOT","vvv")); mixin BEFORE it. It'll all probably work out if you know what you're doing but I'm not making any guarentees as I haven't tested the module extensively.

####Urinary Operators
##### NOT
If the provided version is not active, the resulting version will be active.
```D
mixin(Version("NOT","x32")); //or
mixin(VersionNOT("x32"));

version(NOTx32);
```
####Binary Operators
These examples use Version, but subbing them out for Debug will produce the same but for debug statemets.
#####AND

The new version will only be active if both specified versions are active.
```D
mixin(Version("win","AND","x32")); //or
mixin(VersionAND("win","x32"));

version(winANDx32); //or
version(x32ANDwin);
```
#####OR

The new version will only be active if one or both the specified versions are active.
```D
mixin(Version("win","OR","x32")); //or
mixin(VersionOR("win","x32"));

version(winORx32); //or
version(x32ORwin);
```
#####XOR

The new version will only be avtive if one, but not both, of the specified versions are active.
```D
mixin(Version("win","XOR","x32")); //or
mixin(VersionXOR("win","x32"));

version(winXORx32); //or
version(x3X2ORwin);
```
####Varying Operations


#####Umbrealla
Umbrellas are versions that switch on all of the sub versions when they're active. It is therefore recommended that you do not use version statements with an umbrella version, rather, switch them on at build to switch on groups of versions. An example would be if you had debug code for various input devices under debug(mouse) debug(keyboard) debug(microphone) then you'd make an "input" debug umbrella that you could switch on when you build to switch on all your input debug code.
```D
mixin(Version("u","Umbra","parasol","umbrella","raincoat")); //or
mixin(VersionUmbrella("Umbra","parasol","umbrella","raincoat"));

version(Umbra); //Don't use these like this
```
#####Base
Base versions are the opposite of umbrellas, in that any of the added versions will switch on a base version. Say you had some debug code that needed to be turned on if you're debugging any of a list of things, then you'd use a base.
```D
mixin(Version("b","Umbra","parasol","umbrella","raincoat")); //or
mixin(VersionBase("Umbra","parasol","umbrella","raincoat"));

version(Umbra);
```
#####ManyAND
Will AND together as many conditions as you want into a new named version.
```D
mixin(Version("AND","Umbra","parasol","umbrella","raincoat","...")); //or
mixin(VersionManyAND("Umbra","parasol","umbrella","raincoat","..."));

version(Umbra);
```
###Changing Grammar

As debug statements, versions statements, and mixins are all compile time you're going to need to edit constant values to change the default grammar rules. Below are the relivant ones in versioning.d:
```D
enum Grammar : string {
	SeparatorOR = "OR", //Editing separators will change the behaviour
	SeparatorAND = "AND", //of Version() and Debug calls to the new values
	SeparatorXOR = "XOR",
	PrefixNOT = "NOT",
	SuffixNOT = "",
	Prefix = "", //Global prefix -does not override
	Suffix = "", // Global suffix -does not override
	PrefixOR = "",
	SuffixOR = "",
	PrefixXOR = "",
	SuffixXOR = "",
	PrefixAND = "",
	SuffixAND = "",
	KeyUmbrella = "u",
	KeyBase = "b"
}
```
If you'd like to provide grammar on a per mixin basis, you need to provide additional strings to the specific Version or Debug calls:
```D
//Urinary
mixin(VersionNOT("ver","prefix_","_suffix"));

version(prefix_ver_suffix)

//Binary
mixin(VersionOR("ver","sion","_separator_","prefix_","_suffix"));
mixin(VersionXOR("ver","sion","_separator_","prefix_","_suffix"));
mixin(VersionAND("ver","sion","_separator_","prefix_","_suffix"));

version(prefix_ver_separator_sion_suffix)
version(prefix_sion_separator_ver_suffix)
```
Varying operations do not have setable grammar as a new name is provided per call.

---
I just want to make a comment regarding versions in D in general. Obviously this module is a hack, otherwise clean boolean operators would be provided in the language itself for version and debug statements (they may well appear in future). The logic behind not providing these operators is that it's very easy to screw up your release code, and that opinion has some merit to it, but it also makes testing far too general. If you're writing good code, you're probably only going to use this module lightly, and mostly for debug statements.

If you are using this module for anything, make sure you do some tests to ensure it's working the way you expect.

If you find any issues with the module then bring up an issue, make a pull request, or send me a message and we'll see if we can fix it. :) Feel free to ask a question on the issue tracker, someone else might want to ask the same thing later and they might be able to quickly get their answer by searching in there.

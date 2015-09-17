module versioning;
/*
 * ========================== BOOST LICENCE ===========================
 * |             http://www.boost.org/LICENSE_1_0.txt                 |
 * ====================================================================
 * Do whatever you want man, I don't care. Just don't blame me when
 * you screw up. And oh boy, you're going to want to be careful with
 * this module.
 * ====================================================================
 *                            ^
 *  ~~ Versioning ~~                            ^
 *                                                            ^
 *  Logical operations for version and debug tags in the D Language        
 *
 *         ^                                         by Dmetri Wolf
 *                        ^                                        ^
 *                           ^    ^               ^
 *                   Ooo   
 *                       Oo                      sunset sunset
 *    ^                  __||_____           sunset splash sunset
 * ~~~~~~~~~~~~~~~~~~~~~ \_______/ ~~~~~~~~sunset in the background~~
 *   ~~             ~~ ~~            ~            ~~ ~       ~~       ~~
 * --------------------------------------------------------------------
 * | Meanwhile, in another tab... | 
 * --------------------------------
 * You've discovered that Walter doesn't want you to use boolean 
 * operations in your versioning. Maybe he's right, but we gotta 
 * make our own mistakes. ;)
 * ---
 * This module was created to make debugging a little less annoying.
 * Don't get me wrong, debugging still sucks, but at least you can
 * be pretty specific about which version of your output you're going
 * to get and when. Just don't cock it up or someone will say "I told
 * you so."
 *
 * You have to fill in some mixins at module scope, but then you can
 * put a nice debug(mouseANDkeyboard) next to the debug output of your
 * ctrl+click code.
 *
 * --------- Features all your favourite boolean operators! ----------
 * - OR: creates a logical OR version between two versions 
 *     (either version turns on OR versions)
 * - AND: creates a logical AND version between two versions
 *     (only both versions on will turn on this version)
 * - XOR: creates a logical OR version between two versions
 *     (one or the other version will switch on this version, but not both)
 * - NOT: creates an opposite version of the provided version
 *     (Literally just NOTversion)
 * - ManyAND: combines multiple versions into a new, defined version
 *     (ANDs as many versions as you like, but you provide new name)
 * PLUS OTHER USEFUL THINGS SUCH AS:
 * - Umbrella: creates an umbrella term out of several versions
 *     (all child versions will switch on when umbrella term is used)
 * - Base: creates a base version for a group of versions
 *     (if any of the child versions switches on it will be switched on)
 *
 * ---------- IMPORTANT NOTICES -----------
 * -- Feeding is UNDEFINED --
 * There aren't any guarentees feeding one result into another will
 * do what you expect, eg "mixin(XOR("NOTvers1","vers2ORvers3"));" may or
 * may not work as you expect. I expect that case will work if you've already
 * produced NOTvers1 and vers2ORvers3, but if you start throwning Umbrellas
 * in there the order you have to write it all in might not be very clear.
 * Feeding will also produce lots of very ugly versions, so, taking the example,
 * you could be using version(NOTvers1XORvers2ORvers3) which would be...
 * ...you have eyes, you can see why that's not so great.
 *
 * -- You can use the new versions in any order! --
 * mixin( Version( "sandwich", "AND", "pizza" ) ); will result in both
 * sandwichANDpizza and pizzaANDsandwich so you don't have to remember
 * which order you defined them as. 
 *
 * -- !!! ORDER OF USE !!! --------------------------------------------------+
 * It is recommended that you use Umbrella before using the other finctons   |
 * as Umbrella may need to switch on versions to be used by those functions. |
 * If you are feeding(see above), then you need to determine those BEFORE    |
 * you feed them in.                                                         |
 * --------------------------------------------------------------------------+
 * --- Example --
	module animals;

	import std.stdio;
	import versioning;

	// Base will turn on if any of its children are present 
	// but it will not turn on its children
	// use it in your code when any of its children could satisfy a condition
	mixin( VersionBase( "mammal", "dog", "cat", "mouse" ) ); // mammal

	// Umbrella will only be active if turned on explicitly a la -version=animal
	// all of its children will then be active, usually you won't use an Umbrella
	// in your main code, it just works as a master switch to turn on other things.
	mixin( VersionUmbrella( "animal", "dog", "cat", "mouse", "frog" ) ); // animal

	// Be careful not to confuse the above two.

	mixin( VersionOR( "dog", "cat" ) ); // dogORcat
	mixin( VersionAND( "dog", "cat" ) ); // dogANDcat
	mixin( VersionNOT( "mouse" ) ); // NOTmouse
	mixin( VersionXOR( "cat", "mouse" ) ); // catXORmouse
	mixin( VersionNOT( "animal" ) ); // NOTanimal
	mixin( VersionNOT( "mammal" ) ); // NOTmammal
	mixin( VersionAND( "NOTmammal", "frog" ) ); // NOTmammalANDfrog
	
	//These will do whatevs
	mixin( Debug( "u", "alphabet", "a", "k" ) ); //umbrella named alphabet
	mixin( Version( "b", "alpha", "a", "k" ) ); //base named alpha

	mixin( Version( "sandwich", "XOR", "pizza" ) ); // sandwichXORpizza
	                    							//you're welcome.
	void main(){
	    version(dogORcat) writeln("*something rustles in the bushes*");
	    version(catANDdog) writeln("Woof woof, meow!"); //order of version doesn't matter
	    version(mouseXORcat) writeln("Your pet doesn't seem concerned with anything.");
	    version(NOTmouse) writeln("You have so much cheese right now.");
		version(NOTanimal) writeln("There could be animals here, idk...");
		version(mammal) writeln("Certainly there's something warm blooded here!");
		version(NOTmammal) writeln("Welp, at least there's no hair on the carpet");
		version(frogANDNOTmammal) writeln("It's just you and me, my slimy little friend...");
		version(NOTdog) // won't be called as it's not defined anywhere
	}
 * --- /Example ---
 *
 * As you can see, you have to place a mixin at the module scope each time you want to use
 * one of these operations. It's tedious. Don't blame me, talk to Walter about it. Maybe     
 * he's doing you a favour, making it too damn annoying to lazily screw up your versions.
 *
 * I haven't run any tests on how much impact creating many compile-time mixins/statements
 * is going to have on how fast you can compile.
 */

import std.format, core.vararg;

// Pretty self explanitory. 
// Change these to change global Grammar rules.
enum Grammar : string {
	SeparatorOR = "OR",
	SeparatorAND = "AND",
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

//Version section
string Version( string[] arguments... ){
// Easy function to call each of the others with readable syntax:
// mixin(Version("dog","OR","cat"));
// ManyAND works with // mixin(Version("AND","ANDermals","dog","cat","mouse")); // ANDermals
// Umberella are called with "u" and "b respectively
// Just be careful that you use the right grammar
// You can't use on the fly grammar or write in suffixes etc
	if( arguments[0] == Grammar.PrefixNOT ){
		return VersionNOT(arguments[1]);
	} else if( arguments[1] == Grammar.SeparatorOR ){
		return VersionOR(arguments[0],arguments[2]);
	} else if( arguments[1] == Grammar.SeparatorXOR ){
		return VersionXOR(arguments[0],arguments[2]);
	} else if( arguments[1] == Grammar.SeparatorAND ){
		return VersionAND(arguments[0],arguments[2]);
	} else if( arguments[0] == Grammar.KeyUmbrella ){
		return VersionUmbrella( arguments[1], arguments[2..$] );
	} else if( arguments[0] == Grammar.KeyBase ){
		return VersionBase( arguments[1], arguments[2..$] );
	} else if( arguments[0] == Grammar.SeparatorAND ){
		return VersionManyAND( arguments[1], arguments[2..$] );
	}
	assert(0, "Versioning Version(string...) was use incorrectly.");
}

string VersionUmbrella( string umbrella_term, string[] subsidiaries... ){
	return Umbrella( "version", umbrella_term, subsidiaries );
}
string VersionBase( string base_term, string[] derivatives... ){
	return Base( "version", base_term, derivatives );
}
string VersionManyAND( string new_name, string[] subsidiaries... ){
	return ManyAND( "version", new_name, subsidiaries );
}
string VersionOR( string version1, string version2, string separator = "", 
  string prefix = "", string suffix = "" ){
	return OR( "version", version1, version2, separator, prefix, suffix );
}
string VersionAND( string version1, string version2, string separator = "", 
  string prefix = "", string suffix = "" ){
	return AND( "version", version1, version2, separator, prefix, suffix );
}
string VersionXOR( string version1, string version2, string separator = "", 
  string prefix = "", string suffix = "" ){
	return XOR( "version", version1, version2, separator, prefix, suffix );
}
string VersionNOT( string version1, string prefix = "", string suffix = "" ){
	return NOT( "version", version1, prefix, suffix );
}
//Debug section
string Debug( string[] arguments... ){
	if( arguments[0] == Grammar.PrefixNOT ){
		return DebugNOT(arguments[1]);
	} else if( arguments[1] == Grammar.SeparatorOR ){
		return DebugOR(arguments[0],arguments[2]);
	} else if( arguments[1] == Grammar.SeparatorXOR ){
		return DebugXOR(arguments[0],arguments[2]);
	} else if( arguments[1] == Grammar.SeparatorAND ){
		return DebugAND(arguments[0],arguments[2]);
	} else if( arguments[0] == Grammar.KeyUmbrella ){
		return DebugUmbrella( arguments[1], arguments[2..$] );
	} else if( arguments[0] == Grammar.KeyBase ){
		return DebugBase( arguments[1], arguments[2..$] );
	} else if( arguments[0] == Grammar.SeparatorAND ){
		return DebugManyAND( arguments[1], arguments[2..$] );
	}
	assert(0, "Versioning Version(string...) was use incorrectly.");
}
string DebugUmbrella( string umbrella_term, string[] subsidiaries... ){
	return Umbrella( "debug", umbrella_term, subsidiaries );
}
string DebugBase( string base_term, string[] derivatives... ){
	return Base( "version", base_term, derivatives );
}
string DebugManyAND( string new_name, string[] subsidiaries... ){
	return ManyAND( "debug", new_name, subsidiaries );
}
string DebugOR( string version1, string version2, string separator = "", 
  string prefix = "", string suffix = "" ){
	return OR( "debug", version1, version2, separator, prefix, suffix );
}
string DebugAND( string version1, string version2, string separator = "", 
  string prefix = "", string suffix = "" ){
	return AND( "debug", version1, version2, separator, prefix, suffix );
}
string DebugXOR( string version1, string version2, string separator = "", 
  string prefix = "", string suffix = "" ){
	return XOR( "debug", version1, version2, separator, prefix, suffix );
}
string DebugNOT( string version1, string prefix = "NOT", string suffix = "" ){
	return NOT( "debug", version1, prefix, suffix );
}
/* String constructors for each type of operation, independant of keyword used. */
private:
string Umbrella( string term, string umbrella_term,
  string[] subsidiaries...){
	string all = format( "%s(%s){\n", term, umbrella_term );
	foreach( sub; subsidiaries ){
		all = format( "%s%s = %s;\n", all, term, sub );
	}
	all = format( "%s}", all );
	return all;
}
string Base( string term, string base_term,
  string[] derivatives...){
	string all;
	foreach( sub; derivatives ){
		all = format( "%s%s(%s) %s = %s;\n", all, term, sub, term, base_term );
	}
	return all;
}
string OR( string term, string version1, string version2, 
  string separator = "", string prefix = "", string suffix = "" ){
  	string s = separator;
  	if( separator == "" ){
		s = Grammar.SeparatorOR;
	}
	string p = prefix;
	if( prefix == "" ){
		p = Grammar.PrefixOR;
		if( p == "" ){
			p = Grammar.Prefix;
		}
	}
	string su = suffix;
	if( suffix == "" ){
		su = Grammar.SuffixOR;
		if( su == "" ){
			su= Grammar.Suffix;
		}
	}
	return format( "%s(%s) %s = %s%s%s%s%s;\n%s(%s) %s = %s%s%s%s%s;
%s(%s) %s = %s%s%s%s%s;\n%s(%s) %s = %s%s%s%s%s;", 
	  term, version1, term, p, version1, s, version2, su, term, version2, term, 
	  p, version1, s, version2, su, term, version1, term, p, version2, s, 
	  version1, su, term, version2, term, p, version2, s, version1, su );
}
string AND( string term, string version1, string version2, 
  string separator = "", string prefix = "", string suffix = "" ){
	string s = separator;
  	if( separator == "" ){
		s = Grammar.SeparatorAND;
	}
	string p = prefix;
	if( prefix == "" ){
		p = Grammar.PrefixAND;
		if( p == "" ){
			p = Grammar.Prefix;
		}
	}
	string su = suffix;
	if( suffix == "" ){
		su = Grammar.SuffixAND;
		if( su == "" ){
			su= Grammar.Suffix;
		}
	}
	return format( "%s(%s)%s(%s) %s = %s%s%s%s%s;\n%s(%s)%s(%s) %s = %s%s%s%s%s;", term, version1, 
	 term, version2, term, p, version1,
	  s, version2, su, term, version1, term, version2, term, p, version2, 
	  s, version1, su );
}
string ManyAND( string term, string name, string[] versions... ){
	string s;
	import std.stdio;
	foreach( vers; versions[] ){
		s = format( "%s%s(%s)", s, term, vers );
	}
	s = format( "%s %s = %s;", s, term, name );
	return s;
}
string XOR( string term, string version1, string version2, 
  string separator = "", string prefix = "", string suffix = "" ){
  	string s = separator;
  	if( separator == "" ){
		s = Grammar.SeparatorXOR;
	}
	string p = prefix;
	if( prefix == "" ){
		p = Grammar.PrefixXOR;
		if( p == "" ){
			p = Grammar.Prefix;
		}
	}
	string su = suffix;
	if( suffix == "" ){
		su = Grammar.SuffixXOR;
		if( su == "" ){
			su= Grammar.Suffix;
		}
	}

	return format( "%s(%s){\n%s(%s){\n} else {\n%s = %s%s%s%s%s;\n%s = %s%s%s%s%s;\n}
} else {\n%s(%s){\n%s = %s%s%s%s%s;\n%s = %s%s%s%s%s;\n}\n}", 
	  term, version1, term, version2, term, p, version1, s, version2, su, term, p, version2, s, version1, su,
	  term, version2, term, p, version1, s, version2, su, term, p, version2, s, version1, su );
}
string NOT( string term, string version1, string prefix = "", string suffix = "" ){
	string p = prefix;
	if( prefix == "" ){
		p = Grammar.PrefixXOR;
		if( p == "" ){
			p = Grammar.Prefix;
		}
	}
	string su = suffix;
	if( suffix == "" ){
		su = Grammar.SuffixXOR;
		if( su == "" ){
			su= Grammar.Suffix;
		}
	}
	return format( "%s(%s){\n}else{\n%s = %s%s%s; \n}\n", term, version1, term,
	  p, version1, su );
}

unittest {
	import std.stdio;
	// mixin(OR( "debug", "ver1", "ver2", "_or_" )); //Error at this scope

	// As these outputs need to be printed at module level they can't be
	// tested as code in a unittest, but they can be printed to the screen.
	writeln( "OR Test: \n", OR( "version", "ver1", "ver2", "_or_" ) );
	writeln( "AND Test: \n", AND( "debug", "ver1", "ver2", "_and_" ) );
	writeln( "XOR Test: \n", XOR( "version", "ver1", "ver2", "_xor_" ) );
	writeln( "NOT Test: \n", NOT( "debug", "name", "not_", "_not" ) );

	writeln( "Umbrealla Test: \n", Umbrella( "debug", "abc", "a", "b", "c", "d" ) );
	writeln( "Base Test: \n", Base( "debug", "food", "cheese", "potato" ) );

	writeln( "Debug Test: umbrella \n", Debug( "u", "weather", "rain", "hail", "snow" ) );
	writeln( "Version Test: base\n", Version( "b", "weather", "rain", "hail", "snow" ) );
	writeln( "Version Test: manyand\n", Version( "AND", "weather", "rain", "hail", "snow" ) );
	writeln( "Debug Test: not \n", Debug( "NOT", "weather" ) );
	writeln( "Version Test: xor\n", Version( "friend", "XOR", "enemy" ) );
	writeln( "Version Test: or\n", Version( "friend", "OR", "enemy" ) );
	writeln( "Version Test: and\n", Version( "friend", "AND", "enemy" ) );
}
/* Test code if unittests worked:

	mixin(DebugOR( "ver1", "ver2", "_or_" ) );
	mixin(VersionAND( "ver1", "ver2", "_and_" ) );
	mixin(VersionXOR( "ver1", "ver2", "_xor_" ) );
	mixin(DebugNOT( "name", "not_", "_not" ) );
	mixin(DebugUmbrella( "abc", "a", "b", "c", "d" ) );
	mixin(VersionBase( "food", "cheese", "potato" ) );
	mixin(Debug( "u", "weather", "rain", "hail", "snow" ) );
	mixin(Version( "b", "weather", "rain", "hail", "snow" ) );
	mixin(Version( "AND", "weather", "rain", "hail", "snow" ) );
	mixin(Debug( "NOT", "weather" ) );
	mixin(Version( "friend", "XOR", "enemy" ) );
	mixin(Version( "friend", "OR", "enemy" ) );
	mixin(Version( "friend", "AND", "enemy" ) );

*/

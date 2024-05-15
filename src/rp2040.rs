use crate::gen_tests;

gen_tests!
[
	resets => 0xA790C14A,
];

mod pins
{
	use crate::gen_tests;
	
	gen_tests!
	[
		gpio => 0x15031A5F,
	];
}

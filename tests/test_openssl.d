import ddl;

version(ddl) mixin declareLibraryAndAlias!("deimos.openssl.aes", "aes");
else import deimos.openssl.aes;

version(ddl) mixin declareLibraryAndAlias!("deimos.openssl.sha", "sha");
else import deimos.openssl.sha;

unittest
{
	version(ddl)
	{
		assert(!aes.isLoaded);
		aes = loadLibrary!(deimos.openssl.aes)("ssl");
		assert(aes.loadedFunctions == ["AES_options", "AES_set_encrypt_key",
		         "AES_set_decrypt_key", "AES_encrypt", "AES_decrypt",
		         "AES_ecb_encrypt", "AES_cbc_encrypt", "AES_cfb128_encrypt",
		         "AES_cfb1_encrypt", "AES_cfb8_encrypt", "AES_ofb128_encrypt",
		         "AES_ctr128_encrypt", "AES_ige_encrypt", "AES_bi_ige_encrypt",
		         "AES_wrap_key", "AES_unwrap_key"]);
	}

	version(ddl)
	{
		assert(!sha.isLoaded);
		sha = loadLibrary!(deimos.openssl.sha)("ssl");
		assert(sha.loadedFunctions == ["SHA_Init", "SHA_Update", "SHA_Final",
				 "SHA", "SHA_Transform", "SHA1_Init", "SHA1_Update",
				 "SHA1_Final", "SHA1", "SHA1_Transform", "SHA224_Init",
				 "SHA224_Update", "SHA224_Final", "SHA224", "SHA256_Init",
				 "SHA256_Update", "SHA256_Final", "SHA256", "SHA256_Transform",
				 "SHA384_Init", "SHA384_Update", "SHA384_Final", "SHA384",
				 "SHA512_Init", "SHA512_Update", "SHA512_Final", "SHA512",
				 "SHA512_Transform" ]);
	}

	ubyte[] ibuf = [0x61, 0x62, 0x63];
	ubyte[20] obuf;
	SHA1(ibuf.ptr, ibuf.length, obuf.ptr);

	assert(obuf == [0xA9, 0x99, 0x3E, 0x36, 0x47, 0x06, 0x81, 0x6A, 0xBA,0x3E,
	                0x25, 0x71, 0x78, 0x50, 0xC2, 0x6C, 0x9C, 0xD0, 0xD8, 0x9D]);
}

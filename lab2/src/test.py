a0 = 0x9d29a982563bf87a5814dfc70059a3772cf98a11099f093a2e95d5a874836dd8 # a is encryped text
#a = 0x9d29_a982_563b_f87a_5814_dfc7_0059_a377_2cf9_8a11_099f_093a_2e95_d5a8_7483_6dd8
d = 0xb6ac_e0b1_4720_1698_39b1_5fd1_3326_cf1a_1829_beaf_c37b_b937_bec8_802f_bcf4_6bd9
n = 0xca35_86e7_ea48_5f3b_0a22_2a4c_79f7_dd12_e853_88ec_cdee_4035_940d_774c_029c_f831
b = 0x6228_3572_9cf8_9496_4298_124e_9f99_78b6_0d7d_2db3_a720_389f_56d3_2126_0ab8_b553
mont = 0x651a_c373_f524_2f9d_8511_1526_3cfb_ee89_7429_c476_66f7_201a_ca06_bba6_014e_7c18


def mul_mont(a, b, n):
    """return a*b*2^(-256) % n"""
    ret = 0 # Note: ret must has 257b [0,2n)
    for i in range(256):
        if a & (1<<i):
            ret += b
            #print(hex(ret))
        if ret & 1:
            ret += n
        #print(hex(ret))
        ret >>= 1
        #if i == 1:
         #   break
    return ret if ret<n else ret-n # [0,n) now

def power_mont(a, b, n):
    a2 = mont_preprocess(a+0, n)
    print(hex(a2))
    ret = 1
    # print hex(ret)
    for i in range(256):
        print(str(i)+" th iter")
        if b & (1<<i):
            ret = mul_mont(ret, a2, n)
        print("m= ", hex(ret))
        a2 = mul_mont(a2, a2, n)
        print("t= ", hex(a2))
        
    return ret

def mont_preprocess(a, n):
    """return a*2^(256) % n"""
    for i in range(256):
        a <<= 1
        if a >= n:
            a -= n
    # or, equivalent to this
    # return (a<<256)%n
    return a

#mul_mont(1, b, n)
print(hex(power_mont(a0,d,n)))
#print(hex((a0*(2**256))%n))

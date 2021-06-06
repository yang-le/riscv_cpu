#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H

#define TESTUTIL_BASE 0x20000000
#define TESTUTIL_ADDR_HALT (TESTUTIL_BASE + 0x0)
#define TESTUTIL_ADDR_BEGIN_SIGNATURE (TESTUTIL_BASE + 0x4)
#define TESTUTIL_ADDR_END_SIGNATURE (TESTUTIL_BASE + 0x8)

#define RVMODEL_HALT                                                    \
  /* tell simulation about location of begin_signature */               \
  la t0, begin_signature;                                               \
  li t1, TESTUTIL_ADDR_BEGIN_SIGNATURE;                                 \
  sw t0, 0(t1);                                                         \
  /* tell simulation about location of end_signature */                 \
  la t0, end_signature;                                                 \
  li t1, TESTUTIL_ADDR_END_SIGNATURE;                                   \
  sw t0, 0(t1);                                                         \
  /* dump signature and terminate simulation */                         \
  li t0, 1;                                                             \
  li t1, TESTUTIL_ADDR_HALT;                                            \
  sw t0, 0(t1);                                                         \

#define RVMODEL_DATA_BEGIN                                              \
  .align 4; .global begin_signature; begin_signature:

#define RVMODEL_DATA_END                                                \
  .align 4; .global end_signature; end_signature:

#define RVMODEL_BOOT
#define RVMODEL_IO_INIT
#define RVMODEL_IO_ASSERT_GPR_EQ(ScrReg, Reg, Value)
#define RVMODEL_IO_WRITE_STR(ScrReg, String)

#define RVMODEL_SET_MSW_INT
#define RVMODEL_CLEAR_MSW_INT
#define RVMODEL_CLEAR_MTIMER_INT
#define RVMODEL_CLEAR_MEXT_INT

#endif // _COMPLIANCE_MODEL_H

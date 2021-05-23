#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H

#define RVMODEL_HALT                                                    \
  self_loop:  j self_loop;

#define RVMODEL_DATA_BEGIN                                              \
  .align 4; .global begin_signature; begin_signature:

#define RVMODEL_DATA_END                                                \
  .align 4; .global end_signature; end_signature:

#define RVMODEL_BOOT
#define RVMODEL_IO_ASSERT_GPR_EQ(ScrReg, Reg, Value)

#define RVMODEL_SET_MSW_INT
#define RVMODEL_CLEAR_MSW_INT
#define RVMODEL_CLEAR_MTIMER_INT
#define RVMODEL_CLEAR_MEXT_INT

#endif // _COMPLIANCE_MODEL_H

#! /bin/bash -x

~/Dropbox/Inbox/scale3/sbin/MacOSX-ifort/spd2bin GRID_DXYZ=500 \
                                                 GRID_IMAX=120 \
                                                 GRID_JMAX=120 \
                                                 GRID_KMAX=25  \
                                                 PRC_nmax=6    \
                                                 PRC_NUM_X=3   \
                                                 PRC_NUM_Y=2   \
                                                 gridfile=grid_500m_120x120x25 \
                                                 check_coldbubble_63072000080.000
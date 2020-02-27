#!/bin/sh

iverilog -W all -o isoiec7816 isoiec7816_tb.v isoiec7816_device.v isoiec7816_card.v isoiec7816_transmitter.v isoiec7816_receiver.v || exit 1

IVERILOG_DUMPER=lxt2 vvp isoiec7816

gtkwave isoiec7816_tb.lxt

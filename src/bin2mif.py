#!/usr/bin/env python3

import sys
import os

import click
import mif
import numpy as np


def error(msg):
    print(f'Error: {msg}')
    exit(1)


@click.command()
@click.argument('input', type=click.Path(exists=True))
@click.argument('output', type=click.Path())
@click.option('-f', '--force', is_flag=True, help='allow overriding of output file')
@click.option('-w', '--word-width', type=click.INT, default=32, help='bit width of each word in each file, -1 for one pixel per word')
@click.option('-r', '--dump-radix', type=click.Choice(['HEX', 'BIN']), default='HEX', help='radix to use when dumping data')
def process(input, output, force, word_width, dump_radix):

    if word_width % 8 != 0:
        error('word width must be a multiple of 8')

    word_length = word_width // 8

    # print parameters
    print('======Parameters======')
    print(f'Input file: {input}')
    print(f'Output file: {output}')
    print(f'Word width: {word_width} bits ({word_length} bytes)')
    print('=======Output=========')

    if os.path.exists(output) and not force:
        error('output file existed, use --force to overwrite')

    mem = np.fromfile(input, dtype=np.uint8)

    mem_size = mem.shape[0] # in bytes

    print(f'Input file size: {mem_size} bytes')
    if mem_size % word_length != 0:
        pad_bytes = word_length - mem_size % word_length
        print(f'Padding bytes: {pad_bytes}')
        mem = np.append(mem, np.zeros(shape=(pad_bytes,), dtype=np.uint8))

    mem_size = mem.shape[0]
    word_count = mem_size // word_length

    print(f'Memory size: {mem_size} bytes')
    print(f'Depth (word count): {word_count}')

    # reshape to (address, word)
    mem = mem.reshape((word_count, word_length))

    with open(output, 'w') as f:
        mif.dump(mem, f, packed=True, data_radix=dump_radix)
    
    print('Dump succeeded!')

if __name__ == '__main__':
    process()

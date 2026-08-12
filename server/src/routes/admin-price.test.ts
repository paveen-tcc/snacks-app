import { describe, expect, test } from 'bun:test';
import { normalizePriceRupees } from './admin';

describe('normalizePriceRupees', () => {
    test.each([
        [0, 0],
        [25, 25],
    ])('accepts whole non-negative rupees (%p)', (input, expected) => {
        expect(normalizePriceRupees(input)).toBe(expected);
    });

    test.each([-1, 12.5])('rejects invalid rupee prices (%p)', (input) => {
        expect(() => normalizePriceRupees(input)).toThrow(
            'priceRupees must be a whole number greater than or equal to 0',
        );
    });
});

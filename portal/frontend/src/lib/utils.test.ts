import { describe, it, expect } from 'vitest';
import {
  cn,
  formatDate,
  formatDateTime,
  formatCurrency,
  getStatusColor,
  getPriorityColor,
  truncate,
} from './utils';

// ============ cn() Tests ============

describe('cn', () => {
  it('merges class names correctly', () => {
    const result = cn('px-2 py-1', 'px-4');
    expect(result).toBe('py-1 px-4');
  });

  it('handles conditional classes', () => {
    const isActive = true;
    const result = cn('base-class', isActive && 'active-class');
    expect(result).toContain('base-class');
    expect(result).toContain('active-class');
  });

  it('handles false conditionals', () => {
    const isActive = false;
    const result = cn('base-class', isActive && 'active-class');
    expect(result).toBe('base-class');
  });

  it('handles empty inputs', () => {
    const result = cn();
    expect(result).toBe('');
  });

  it('handles undefined and null', () => {
    const result = cn('base', undefined, null, 'end');
    expect(result).toBe('base end');
  });
});

// ============ formatDate() Tests ============

describe('formatDate', () => {
  it('formats valid date string', () => {
    const result = formatDate('2024-12-25');
    expect(result).toMatch(/25.*Des.*2024/);
  });

  it('returns dash for undefined', () => {
    const result = formatDate(undefined);
    expect(result).toBe('-');
  });

  it('handles ISO date format', () => {
    const result = formatDate('2024-01-15T10:30:00Z');
    expect(result).toMatch(/15.*Jan.*2024/);
  });
});

// ============ formatDateTime() Tests ============

describe('formatDateTime', () => {
  it('formats date with time', () => {
    const result = formatDateTime('2024-12-25T14:30:00Z');
    expect(result).toMatch(/25.*Des.*2024/);
    // Should contain time
    expect(result).toMatch(/\d{2}[.:]\d{2}/);
  });

  it('returns dash for undefined', () => {
    const result = formatDateTime(undefined);
    expect(result).toBe('-');
  });
});

// ============ formatCurrency() Tests ============

describe('formatCurrency', () => {
  it('formats currency in USD', () => {
    const result = formatCurrency(1000);
    expect(result).toMatch(/\$1,000/);
  });

  it('returns dash for undefined', () => {
    const result = formatCurrency(undefined);
    expect(result).toBe('-');
  });

  it('handles zero', () => {
    const result = formatCurrency(0);
    expect(result).toMatch(/\$0/);
  });

  it('handles decimals', () => {
    const result = formatCurrency(99.99);
    expect(result).toMatch(/\$99\.99/);
  });

  it('handles large numbers', () => {
    const result = formatCurrency(1000000);
    expect(result).toMatch(/\$1,000,000/);
  });
});

// ============ getStatusColor() Tests ============

describe('getStatusColor', () => {
  it('returns correct color for draft status', () => {
    const result = getStatusColor('draft');
    expect(result).toBe('bg-gray-100 text-gray-800');
  });

  it('returns correct color for pending status', () => {
    const result = getStatusColor('pending');
    expect(result).toBe('bg-yellow-100 text-yellow-800');
  });

  it('returns correct color for approved status', () => {
    const result = getStatusColor('approved');
    expect(result).toBe('bg-green-100 text-green-800');
  });

  it('returns correct color for rejected status', () => {
    const result = getStatusColor('rejected');
    expect(result).toBe('bg-red-100 text-red-800');
  });

  it('returns correct color for planning status', () => {
    const result = getStatusColor('planning');
    expect(result).toBe('bg-blue-100 text-blue-800');
  });

  it('returns correct color for applied status', () => {
    const result = getStatusColor('applied');
    expect(result).toBe('bg-green-100 text-green-800');
  });

  it('returns correct color for failed status', () => {
    const result = getStatusColor('failed');
    expect(result).toBe('bg-red-100 text-red-800');
  });

  it('returns default gray for unknown status', () => {
    const result = getStatusColor('unknown');
    expect(result).toBe('bg-gray-100 text-gray-800');
  });
});

// ============ getPriorityColor() Tests ============

describe('getPriorityColor', () => {
  it('returns correct color for low priority', () => {
    const result = getPriorityColor('low');
    expect(result).toBe('bg-slate-100 text-slate-800');
  });

  it('returns correct color for normal priority', () => {
    const result = getPriorityColor('normal');
    expect(result).toBe('bg-blue-100 text-blue-800');
  });

  it('returns correct color for high priority', () => {
    const result = getPriorityColor('high');
    expect(result).toBe('bg-orange-100 text-orange-800');
  });

  it('returns correct color for urgent priority', () => {
    const result = getPriorityColor('urgent');
    expect(result).toBe('bg-red-100 text-red-800');
  });

  it('returns default gray for unknown priority', () => {
    const result = getPriorityColor('unknown');
    expect(result).toBe('bg-gray-100 text-gray-800');
  });
});

// ============ truncate() Tests ============

describe('truncate', () => {
  it('truncates long strings', () => {
    const result = truncate('This is a very long string', 10);
    expect(result).toBe('This is a ...');
  });

  it('returns original string if shorter than length', () => {
    const result = truncate('Short', 10);
    expect(result).toBe('Short');
  });

  it('returns original string if equal to length', () => {
    const result = truncate('Exactly10!', 10);
    expect(result).toBe('Exactly10!');
  });

  it('handles empty string', () => {
    const result = truncate('', 10);
    expect(result).toBe('');
  });

  it('handles zero length', () => {
    const result = truncate('Test', 0);
    expect(result).toBe('...');
  });
});

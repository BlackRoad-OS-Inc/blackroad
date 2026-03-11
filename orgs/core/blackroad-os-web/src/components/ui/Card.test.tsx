import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { Card } from './Card';

describe('Card', () => {
  it('renders children', () => {
    render(<Card>Card content</Card>);
    expect(screen.getByText('Card content')).toBeInTheDocument();
  });

  it('renders title and subtitle', () => {
    render(
      <Card title="My Title" subtitle="A subtitle">
        Body
      </Card>
    );
    expect(screen.getByText('My Title')).toBeInTheDocument();
    expect(screen.getByText('A subtitle')).toBeInTheDocument();
  });

  it('renders badge', () => {
    render(
      <Card title="Titled" badge="Active">
        Content
      </Card>
    );
    expect(screen.getByText('Active')).toBeInTheDocument();
  });

  it('renders footer', () => {
    render(
      <Card footer={<span>Footer text</span>}>
        Content
      </Card>
    );
    expect(screen.getByText('Footer text')).toBeInTheDocument();
  });

  it('applies agent border color', () => {
    const { container } = render(
      <Card agent="lucidia">Content</Card>
    );
    const card = container.firstChild as HTMLElement;
    expect(card.className).toContain('border-red-500');
  });

  it('applies agent badge styling', () => {
    render(
      <Card title="Agent" agent="alice" badge="Online">
        Content
      </Card>
    );
    const badge = screen.getByText('Online');
    expect(badge.className).toContain('bg-blue-500/20');
  });

  it('uses default border when no agent', () => {
    const { container } = render(<Card>Content</Card>);
    const card = container.firstChild as HTMLElement;
    expect(card.className).toContain('border-white/10');
  });

  it('fires onClick and shows cursor-pointer', () => {
    const handler = vi.fn();
    const { container } = render(
      <Card onClick={handler}>Clickable</Card>
    );
    const card = container.firstChild as HTMLElement;
    expect(card.className).toContain('cursor-pointer');
    fireEvent.click(card);
    expect(handler).toHaveBeenCalledOnce();
  });

  it('does not show cursor-pointer without onClick', () => {
    const { container } = render(<Card>Static</Card>);
    const card = container.firstChild as HTMLElement;
    expect(card.className).not.toContain('cursor-pointer');
  });

  it('merges custom className', () => {
    const { container } = render(
      <Card className="extra-class">Content</Card>
    );
    const card = container.firstChild as HTMLElement;
    expect(card.className).toContain('extra-class');
  });

  it('supports all agent colors', () => {
    const agents = ['lucidia', 'alice', 'octavia', 'prism', 'echo', 'cipher'] as const;
    const expectedBorders = ['border-red-500', 'border-blue-500', 'border-green-500', 'border-yellow-500', 'border-purple-500', 'border-cyan-500'];

    agents.forEach((agent, i) => {
      const { container } = render(<Card agent={agent}>Content</Card>);
      const card = container.firstChild as HTMLElement;
      expect(card.className).toContain(expectedBorders[i]);
    });
  });
});

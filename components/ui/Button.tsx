import { forwardRef, ButtonHTMLAttributes } from 'react';
import { cn } from '@/lib/cn';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
}

const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', children, ...props }, ref) => {
    const baseStyles = 'inline-flex items-center justify-center font-medium transition-all focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-black disabled:opacity-50 disabled:cursor-not-allowed';

    const variants = {
      primary: 'bg-gradient-to-r from-[#FF1D6C] to-violet-600 text-white hover:from-[#FF1D6C]/90 hover:to-violet-600/90 hover:shadow-lg hover:shadow-[#FF1D6C]/25 focus:ring-[#FF1D6C]/50',
      secondary: 'bg-white/10 text-white hover:bg-white/20 focus:ring-white/20',
      outline: 'border border-white/20 text-white hover:bg-white/5 hover:border-white/40 focus:ring-white/20',
      ghost: 'text-gray-400 hover:text-white hover:bg-white/5 focus:ring-white/10',
    };

    const sizes = {
      sm: 'px-3 py-1.5 text-sm rounded-lg gap-1.5',
      md: 'px-4 py-2.5 text-sm rounded-xl gap-2',
      lg: 'px-6 py-3.5 text-base rounded-xl gap-2',
    };

    return (
      <button
        ref={ref}
        className={cn(baseStyles, variants[variant], sizes[size], className)}
        {...props}
      >
        {children}
      </button>
    );
  }
);

Button.displayName = 'Button';

export default Button;

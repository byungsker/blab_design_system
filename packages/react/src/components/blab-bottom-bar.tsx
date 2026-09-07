import type { ReactNode } from "react";

export type BLabBottomBarItem = {
  readonly icon: ReactNode;
  readonly activeIcon: ReactNode;
  readonly label: string;
};

export type BLabBottomBarProps = {
  readonly tabs: readonly BLabBottomBarItem[];
  readonly selectedIndex: number;
  readonly onTabSelected: (index: number) => void;
  readonly onSearchTap?: () => void;
  readonly actionIcon?: ReactNode;
  readonly actionLabel?: string;
  readonly showFirstTabChevron?: boolean;
  readonly onFirstTabChevronTap?: () => void;
  readonly firstTabChevronLabel?: string;
  readonly noMargin?: boolean;
  readonly ariaLabel?: string;
  readonly className?: string;
};

export function BLabBottomBar({
  tabs,
  selectedIndex,
  onTabSelected,
  onSearchTap,
  actionIcon,
  actionLabel = "Action",
  showFirstTabChevron = false,
  onFirstTabChevronTap,
  firstTabChevronLabel = "More options",
  noMargin = false,
  ariaLabel = "Primary navigation",
  className,
}: BLabBottomBarProps) {
  const barClassName = [
    "blab-bottom-bar",
    noMargin ? "blab-bottom-bar--no-margin" : "",
    className ?? "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <nav className={barClassName} aria-label={ariaLabel}>
      <div className="blab-bottom-bar__items">
        {tabs.map((tab, index) => {
          const selected = index === selectedIndex;
          return (
            <div
              key={`${tab.label}-${index}`}
              className="blab-bottom-bar__item-wrap"
            >
              <button
                className="blab-bottom-bar__item"
                type="button"
                aria-current={selected ? "page" : undefined}
                onClick={() => onTabSelected(index)}
              >
                <span aria-hidden="true">{selected ? tab.activeIcon : tab.icon}</span>
                <span>{tab.label}</span>
              </button>
              {showFirstTabChevron && index === 0 && onFirstTabChevronTap ? (
                <button
                  className="blab-bottom-bar__chevron"
                  type="button"
                  aria-label={firstTabChevronLabel}
                  onClick={onFirstTabChevronTap}
                >
                  ⌄
                </button>
              ) : null}
            </div>
          );
        })}
      </div>
      {onSearchTap ? (
        <button className="blab-bottom-bar__action" type="button" aria-label={actionLabel} onClick={onSearchTap}>
          <span aria-hidden="true">{actionIcon ?? "⌕"}</span>
        </button>
      ) : null}
    </nav>
  );
}

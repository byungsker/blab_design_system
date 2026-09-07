import { useState } from "react";

import { BLabBottomBar } from "./components/blab-bottom-bar.js";
import { BLabButton } from "./components/blab-button.js";
import { BLabCard } from "./components/blab-card.js";
import { BLabKeyboardAccessoryBar } from "./components/blab-keyboard-accessory-bar.js";
import { BLabEmptyState, BLabErrorState, BLabLoadingState } from "./components/blab-states.js";
import { BLabSegmentedControl } from "./components/blab-segmented-control.js";
import { BLabSnackbar } from "./components/blab-snackbar.js";
import { BLabTabBar } from "./components/blab-tab-bar.js";
import { BLabTextField } from "./components/blab-text-field.js";

export type BLabParityFixtureProps = {
  readonly theme?: "light" | "dark";
};

export function BLabParityFixture({ theme = "light" }: BLabParityFixtureProps) {
  const [selectedSegment, setSelectedSegment] = useState("first");
  const [selectedTab, setSelectedTab] = useState(0);
  const [selectedBottomTab, setSelectedBottomTab] = useState(0);
  const [value, setValue] = useState("Fixture value");

  return (
    <main data-blab-theme={theme} data-blab-component="parity-fixture" style={{ minHeight: "100vh", padding: 24 }}>
      <BLabTabBar tabs={["First", "Second"]} selectedIndex={selectedTab} onTabSelected={setSelectedTab} ariaLabel="Fixture tabs" />
      <BLabCard style={{ marginTop: 24 }}>
        <BLabTextField label="Field" value={value} onChange={(event) => setValue(event.target.value)} clearLabel="Clear field" onClear={() => setValue("")} />
        <BLabButton text="Primary action" isFullWidth style={{ marginTop: 16 }} onClick={() => undefined} />
      </BLabCard>
      <BLabSegmentedControl
        ariaLabel="Fixture segments"
        items={[{ value: "first", label: "First" }, { value: "second", label: "Second" }]}
        selectedValue={selectedSegment}
        onChanged={setSelectedSegment}
      />
      <BLabLoadingState label="Loading" />
      <BLabEmptyState title="Nothing here" message="There is no content in this state." />
      <BLabErrorState title="Something went wrong" message="Try again to continue." retryLabel="Retry" onRetry={() => undefined} />
      <BLabKeyboardAccessoryBar
        onDone={() => undefined}
        showNavigation
        onUp={() => undefined}
        onDown={() => undefined}
        onUndo={() => undefined}
        onRedo={() => undefined}
        onCopy={() => undefined}
        onClearAll={() => undefined}
        canUndo
        canRedo
        canCopy
        canClearAll
      />
      <BLabSnackbar message="Saved" type="success" />
      <BLabBottomBar
        tabs={[
          { label: "Home", icon: "○", activeIcon: "●" },
          { label: "Library", icon: "□", activeIcon: "■" },
        ]}
        selectedIndex={selectedBottomTab}
        onTabSelected={setSelectedBottomTab}
        ariaLabel="Fixture navigation"
      />
    </main>
  );
}

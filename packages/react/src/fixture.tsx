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
  const [undoEvents, setUndoEvents] = useState<number[]>([]);
  const [longPressCount, setLongPressCount] = useState(0);

  return (
    <main data-blab-theme={theme} data-blab-component="parity-fixture" style={{ minHeight: "100vh", padding: 24 }}>
      <BLabTabBar tabs={["First", "Second"]} selectedIndex={selectedTab} onTabSelected={setSelectedTab} ariaLabel="Fixture tabs" />
      <BLabCard style={{ marginTop: 24 }}>
        <BLabTextField label="Field" value={value} onChange={(event) => setValue(event.target.value)} clearLabel="Clear field" onClear={() => setValue("")} />
        <BLabButton text="Primary action" isFullWidth style={{ marginTop: 16 }} onClick={() => undefined} />
      </BLabCard>
      <section className="blab-fixture-state-gallery" aria-labelledby="blab-fixture-state-title">
        <h2 id="blab-fixture-state-title">Component states</h2>
        <div className="blab-fixture-state-gallery__grid">
          <BLabButton text="Focused button" autoFocus data-state="focused" onClick={() => undefined} />
          <BLabButton text="Disabled button" disabled data-state="disabled" onClick={() => undefined} />
          <BLabButton text="Saving" loading loadingLabel="Saving" data-state="loading" onClick={() => undefined} />
          <div className="blab-fixture-state-gallery__field" data-state="error">
            <BLabTextField
              label="Error field"
              value="Invalid value"
              error="Enter a valid value"
              onChange={() => undefined}
            />
          </div>
          <BLabCard className="blab-fixture-state-gallery__card" onLongPress={() => setLongPressCount((count) => count + 1)}>
            Long-press card
          </BLabCard>
        </div>
      </section>
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
        ariaLabel="Keyboard accessory"
        doneLabel="Done"
        showNavigation
        onUp={() => undefined}
        onDown={() => undefined}
        upLabel="Move up"
        downLabel="Move down"
        onUndo={() => setUndoEvents((events) => [...events, performance.now()])}
        onRedo={() => undefined}
        onCopy={() => undefined}
        onClearAll={() => undefined}
        undoLabel="Undo"
        redoLabel="Redo"
        copyLabel="Copy"
        clearAllLabel="Clear all"
        canUndo
        canRedo
        canCopy
        canClearAll
      />
      <span className="blab-visually-hidden" data-blab-test-output="undo-count">{undoEvents.length}</span>
      <span className="blab-visually-hidden" data-blab-test-output="undo-events">{undoEvents.join(",")}</span>
      <span className="blab-visually-hidden" data-blab-test-output="long-press-count">{longPressCount}</span>
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

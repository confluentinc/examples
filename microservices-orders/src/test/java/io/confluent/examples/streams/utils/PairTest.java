/*
 * Copyright Confluent Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package io.confluent.examples.streams.utils;

import org.junit.Test;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.not;
import static org.hamcrest.MatcherAssert.assertThat;

public class PairTest {

  @Test
  public void shouldSupportEquals() {
    // Given
    final Pair<String, String> pair = new Pair<>("foo", "bar");

    // When/Then
    assertThat(new Pair<>("foo", "bar"), equalTo(pair));
    assertThat(null, not(equalTo(pair)));
    assertThat(new Pair<>("foo", "quux"), not(equalTo(pair)));
    assertThat(new Pair<>("quux", "foo"), not(equalTo(pair)));
    assertThat(new Pair<>("foo", 1), not(equalTo(pair)));
    assertThat(new Pair<>(1, "foo"), not(equalTo(pair)));
  }

}